;; Cros Bridge - Cross-chain Bridge between Bitcoin and Stacks
;; Owner: Contract deployer
;; Error codes:
;; (err u1) - Unauthorized
;; (err u2) - Invalid amount
;; (err u3) - Insufficient balance
;; (err u4) - Bridge paused
;; (err u5) - Invalid bridge operation

(define-data-var contract-owner principal tx-sender)
(define-data-var is-paused bool false)
(define-map balances principal uint)
(define-map bridge-requests (tuple (tx-id (buff 32)) (amount uint) (recipient principal)) bool)

;; Constants
(define-constant MIN_DEPOSIT u100000) ;; Minimum deposit amount (in micro STX)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INVALID_AMOUNT (err u2))
(define-constant ERR_INSUFFICIENT_BALANCE (err u3))
(define-constant ERR_PAUSED (err u4))
(define-constant ERR_INVALID_OPERATION (err u5))

;; Authorization check
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner)))

;; Initialize bridge request
(define-public (initialize-bridge-request (btc-tx-id (buff 32)) (amount uint) (recipient principal))
  (begin
    (asserts! (not (var-get is-paused)) ERR_PAUSED)
    (asserts! (>= amount MIN_DEPOSIT) ERR_INVALID_AMOUNT)
    (asserts! (is-some (get-balance tx-sender)) ERR_INSUFFICIENT_BALANCE)
    (ok (map-set bridge-requests 
      {tx-id: btc-tx-id, amount: amount, recipient: recipient} 
      true))))

;; Complete bridge operation
(define-public (complete-bridge-operation (btc-tx-id (buff 32)) (amount uint) (recipient principal))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (not (var-get is-paused)) ERR_PAUSED)
    (asserts! (map-get? bridge-requests {tx-id: btc-tx-id, amount: amount, recipient: recipient}) ERR_INVALID_OPERATION)
    (map-delete bridge-requests {tx-id: btc-tx-id, amount: amount, recipient: recipient})
    (ok (stx-transfer? amount tx-sender recipient))))

;; Get balance
(define-read-only (get-balance (user principal))
  (map-get? balances user))

;; Admin functions
(define-public (set-paused (paused bool))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (ok (var-set is-paused paused))))

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (ok (var-set contract-owner new-owner))))