;; Cross-chain Bridge Contract
;; Supports multiple tokens and a fee mechanism

(define-map bridge-requests
    { tx-id: (buff 32), token: principal, amount: uint, recipient: principal }
    { processed: bool, timestamp: uint })

(define-map supported-tokens principal bool)
(define-map processed-txs (buff 32) bool)
(define-map claims {token: principal, user: principal} uint)
(define-trait ft-trait
    (
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))
        (get-name () (response (string-ascii 32) uint))
        (get-symbol () (response (string-ascii 32) uint))
        (get-decimals () (response uint uint))
        (get-balance (principal) (response uint uint))
        (get-total-supply () (response uint uint))
        (get-token-uri () (response (optional (string-utf8 256)) uint))
    )
)

(define-constant MIN_DEPOSIT u100000)
(define-constant CLAIM_TIMEOUT u144)
(define-constant FEE_BPS u100) ;; 1% fee

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INVALID_AMOUNT (err u2))
(define-constant ERR_INSUFFICIENT_BALANCE (err u3))
(define-constant ERR_PAUSED (err u4))
(define-constant ERR_INVALID_OPERATION (err u5))
(define-constant ERR_INVALID_TX (err u6))
(define-constant ERR_ALREADY_CLAIMED (err u7))
(define-constant ERR_CLAIM_EXPIRED (err u8))
(define-constant ERR_INVALID_RECIPIENT (err u9))
(define-constant ERR_INVALID_TX_ID (err u10))
(define-constant ERR_TOKEN_NOT_SUPPORTED (err u11))
(define-constant ERR_FEE_CALCULATION_FAILED (err u12))


;; Data Variables and Maps
(define-data-var contract-owner principal tx-sender)
(define-data-var is-paused bool false)
(define-data-var min-amount uint MIN_DEPOSIT)
(define-data-var fee-bps uint FEE_BPS)

(define-map balances {token: principal, user: principal} uint)

;; Helper Functions
(define-private (is-valid-amount (amount uint))
    (>= amount (var-get min-amount)))

(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner)))

(define-private (check-processed (tx-id (buff 32)))
    (default-to false (map-get? processed-txs tx-id)))

(define-private (validate-recipient (recipient principal))
    (and
        (not (is-eq recipient tx-sender))
        (not (is-eq recipient (var-get contract-owner)))))

(define-private (is-token-supported (token principal))
  (default-to false (map-get? supported-tokens token)))

(define-private (get-balance (balance-data {token: principal, user: principal}))
  (default-to u0 (map-get? balances balance-data)))

(define-private (calculate-fee (amount uint))
  (let ((fee (/ (* amount (var-get fee-bps)) u10000)))
    (if (> fee u0)
        (ok fee)
        (err u12))))

(define-private (validate-bridge-data (token <ft-trait>) (amount uint))
    (let ((sender tx-sender))
        (asserts! (not (var-get is-paused)) ERR_PAUSED)
        (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT)
        (asserts! (is-token-supported (contract-of token)) ERR_TOKEN_NOT_SUPPORTED)
        (asserts! (>= (get-balance {token: (contract-of token), user: sender}) amount) ERR_INSUFFICIENT_BALANCE)
        (ok true)))

;; Public Functions
(define-public (initialize-bridge-request (tx-id (buff 32)) (token <ft-trait>) (amount uint) (recipient principal))
    (begin
        (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT)
        (asserts! (> (len tx-id) u0) ERR_INVALID_TX_ID)
        (asserts! (validate-recipient recipient) ERR_INVALID_RECIPIENT)
        (asserts! (is-token-supported (contract-of token)) ERR_TOKEN_NOT_SUPPORTED)
        (let ((validated (try! (validate-bridge-data token amount))))
            (try! (contract-call? token transfer amount tx-sender (as-contract tx-sender) none))
            (map-set processed-txs tx-id true)
            (map-set bridge-requests
                { tx-id: tx-id, token: (contract-of token), amount: amount, recipient: recipient }
                { processed: false, timestamp: block-height })
            (ok true))))

(define-public (complete-bridge-operation (tx-id (buff 32)) (token <ft-trait>) (amount uint) (recipient principal))
    (begin
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT)
        (asserts! (> (len tx-id) u0) ERR_INVALID_TX_ID)
        (asserts! (validate-recipient recipient) ERR_INVALID_RECIPIENT)
        (asserts! (is-token-supported (contract-of token)) ERR_TOKEN_NOT_SUPPORTED)
        (match (map-get? bridge-requests { tx-id: tx-id, token: (contract-of token), amount: amount, recipient: recipient })
            request-data (begin
                (asserts! (not (get processed request-data)) ERR_INVALID_OPERATION)
                (let ((fee (try! (calculate-fee amount)))
                      (remaining-amount (- amount fee)))
                    (try! (as-contract (contract-call? token transfer
                            fee
                            (as-contract tx-sender)
                            (var-get contract-owner)
                            none)))
                    (try! (as-contract (contract-call? token transfer
                        remaining-amount
                        (as-contract tx-sender)
                        recipient
                        none)))
                    (ok (map-set bridge-requests
                        { tx-id: tx-id, token: (contract-of token), amount: amount, recipient: recipient }
                        { processed: true, timestamp: block-height }))))
            ERR_INVALID_OPERATION)))

;; ... (rest of the contract code remains largely the same, 
;;     but adapt functions like claim-failed-bridge, refund-failed-bridge, etc. 
;;     to include the token parameter) ...

;; Admin function to add supported tokens
(define-public (add-supported-token (token <ft-trait>))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (is-ok (contract-call? token get-name)) ERR_INVALID_OPERATION)
    (ok (map-set supported-tokens (contract-of token) true))))

;; Admin function to remove supported tokens
(define-public (remove-supported-token (token principal))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (is-token-supported token) ERR_TOKEN_NOT_SUPPORTED)
    (ok (map-delete supported-tokens token))))

;; Initialize contract (add initial supported token - e.g., STX)
(begin
    (map-set supported-tokens .stx true) ;; Example: STX is initially supported
    (ok true))
