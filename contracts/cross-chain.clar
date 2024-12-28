;; Constants
(define-constant MIN_DEPOSIT u100000)
(define-constant ERR_UNAUTHORIZED (err u1))
(define-constant ERR_INVALID_AMOUNT (err u2))
(define-constant ERR_INSUFFICIENT_BALANCE (err u3))
(define-constant ERR_PAUSED (err u4))
(define-constant ERR_INVALID_OPERATION (err u5))
(define-constant ERR_INVALID_TX (err u6))

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var is-paused bool false)

;; Maps
(define-map balances principal uint)
(define-map bridge-requests 
  { tx-id: (buff 32), amount: uint, recipient: principal }
  { processed: bool, timestamp: uint })

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner)))

(define-private (validate-bridge-data (btc-tx-id (buff 32)) (amount uint) (recipient principal))
  (begin
    (asserts! (not (var-get is-paused)) ERR_PAUSED)
    (asserts! (>= amount MIN_DEPOSIT) ERR_INVALID_AMOUNT)
    (asserts! (>= (get-balance tx-sender) amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (is-none (map-get? bridge-requests 
      { tx-id: btc-tx-id, amount: amount, recipient: recipient })) 
      ERR_INVALID_TX)
    (ok true)))

;; Public Functions
(define-public (initialize-bridge-request (btc-tx-id (buff 32)) (amount uint) (recipient principal))
  (begin 
    (try! (validate-bridge-data btc-tx-id amount recipient))
    (ok (map-set bridge-requests 
      { tx-id: btc-tx-id, amount: amount, recipient: recipient }
      { processed: false, timestamp: block-height }))))

(define-public (complete-bridge-operation (btc-tx-id (buff 32)) (amount uint) (recipient principal))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (let ((request (unwrap! (map-get? bridge-requests 
      { tx-id: btc-tx-id, amount: amount, recipient: recipient })
      ERR_INVALID_OPERATION)))
    (asserts! (not (get processed request)) ERR_INVALID_OPERATION)
    (try! (as-contract (stx-transfer? amount tx-sender recipient)))
    (ok (map-set bridge-requests
      { tx-id: btc-tx-id, amount: amount, recipient: recipient }
      { processed: true, timestamp: block-height })))))

;; Read-only Functions 
(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? balances user)))

(define-read-only (get-bridge-request (btc-tx-id (buff 32)) (amount uint) (recipient principal))
  (map-get? bridge-requests { tx-id: btc-tx-id, amount: amount, recipient: recipient }))

;; Admin Functions
(define-public (set-paused (paused bool))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (ok (var-set is-paused paused))))

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq new-owner tx-sender)) ERR_INVALID_OPERATION)
    (ok (var-set contract-owner new-owner))))

;; Initialize contract
(begin
  (map-set balances tx-sender u1000000000)
  (ok true))