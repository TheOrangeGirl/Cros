;; Cross-chain Bridge Contract
;; Validates bridge operations and handles asset transfers

(define-constant MIN_DEPOSIT u100000) 
(define-constant CLAIM_TIMEOUT u144)

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

;; Data Variables and Maps
(define-data-var contract-owner principal tx-sender)
(define-data-var is-paused bool false)
(define-data-var min-amount uint MIN_DEPOSIT)

(define-map balances principal uint)
(define-map claims principal uint)
(define-map processed-txs (buff 32) bool)
(define-map bridge-requests 
 { tx-id: (buff 32), amount: uint, recipient: principal }
 { processed: bool, timestamp: uint })

;; Bridge Statistics Functions
(define-map total-bridged-by-user principal uint)
(define-map daily-bridge-volume uint uint)

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

(define-private (validate-bridge-data (tx-id (buff 32)) (amount uint) (recipient principal))
 (let ((sender tx-sender))
   (asserts! (not (var-get is-paused)) ERR_PAUSED)
   (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT) 
   (asserts! (>= (get-balance sender) amount) ERR_INSUFFICIENT_BALANCE)
   (asserts! (not (check-processed tx-id)) ERR_INVALID_TX)
   (asserts! (validate-recipient recipient) ERR_INVALID_RECIPIENT)
   (ok true)))

;; Public Functions
(define-public (initialize-bridge-request (tx-id (buff 32)) (amount uint) (recipient principal))
 (begin
   (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT)
   (asserts! (> (len tx-id) u0) ERR_INVALID_TX_ID)
   (asserts! (validate-recipient recipient) ERR_INVALID_RECIPIENT)
   (let ((validated (try! (validate-bridge-data tx-id amount recipient))))
     (map-set processed-txs tx-id true)
     (ok (map-set bridge-requests 
       { tx-id: tx-id, amount: amount, recipient: recipient }
       { processed: false, timestamp: block-height })))))

(define-public (complete-bridge-operation (tx-id (buff 32)) (amount uint) (recipient principal))
 (begin
   (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
   (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT)
   (asserts! (> (len tx-id) u0) ERR_INVALID_TX_ID)
   (asserts! (validate-recipient recipient) ERR_INVALID_RECIPIENT)
   (match (map-get? bridge-requests 
           { tx-id: tx-id, amount: amount, recipient: recipient })
     request (begin
       (asserts! (not (get processed request)) ERR_INVALID_OPERATION)
       (try! (as-contract (stx-transfer? amount tx-sender recipient)))
       (ok (map-set bridge-requests
         { tx-id: tx-id, amount: amount, recipient: recipient }
         { processed: true, timestamp: block-height })))
     ERR_INVALID_OPERATION)))

(define-public (claim-failed-bridge (tx-id (buff 32)) (amount uint))
 (begin
   (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT)
   (asserts! (> (len tx-id) u0) ERR_INVALID_TX_ID)
   (match (map-get? bridge-requests 
           { tx-id: tx-id, amount: amount, recipient: tx-sender })
     request (begin
       (asserts! (not (get processed request)) ERR_ALREADY_CLAIMED)
       (asserts! (>= block-height (+ (get timestamp request) CLAIM_TIMEOUT)) ERR_CLAIM_EXPIRED)
       (map-set claims tx-sender amount)
       (map-set processed-txs tx-id true)
       (ok true))
     ERR_INVALID_OPERATION)))

(define-public (refund-failed-bridge)
 (match (map-get? claims tx-sender)
   claim-amount (begin
     (map-delete claims tx-sender)
     (as-contract (stx-transfer? claim-amount tx-sender tx-sender)))
   ERR_INVALID_OPERATION))

(define-public (emergency-withdraw (amount uint))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (var-get is-paused) ERR_INVALID_OPERATION)
    (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT)
    (try! (as-contract (stx-transfer? amount tx-sender (var-get contract-owner))))
    (ok true)))

(define-public (record-bridge-stats (amount uint))
  (begin
    (asserts! (is-valid-amount amount) ERR_INVALID_AMOUNT)
    (let (
      (current-user-total (default-to u0 (map-get? total-bridged-by-user tx-sender)))
      (current-day-total (default-to u0 (map-get? daily-bridge-volume (/ block-height u144))))
    )
    (map-set total-bridged-by-user tx-sender (+ current-user-total amount))
    (map-set daily-bridge-volume (/ block-height u144) (+ current-day-total amount))
    (ok true))))

(define-public (batch-process-claims (users (list 200 principal)))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (let ((processed-count u0))
      (fold process-user users (ok processed-count)))))

(define-private (process-user (user principal) (previous-result (response uint uint)))
  (match previous-result
    success (match (map-get? claims user)
              claim-amount (begin
                (map-delete claims user)
                (match (as-contract (stx-transfer? claim-amount tx-sender user))
                  transfer-success (ok (+ success u1))
                  transfer-error previous-result))
              (ok success))
    error previous-result))

;; Read-only Functions
(define-read-only (get-balance (user principal))
 (default-to u0 (map-get? balances user)))

(define-read-only (get-bridge-request (tx-id (buff 32)) (amount uint) (recipient principal))
 (map-get? bridge-requests { tx-id: tx-id, amount: amount, recipient: recipient }))

(define-read-only (get-minimum-amount)
 (var-get min-amount))

(define-read-only (get-user-bridge-stats (user principal))
  (let (
    (total-bridged (default-to u0 (map-get? total-bridged-by-user user)))
    (pending-claims (default-to u0 (map-get? claims user))))
  {
    total-bridged: total-bridged,
    pending-claims: pending-claims,
    is-active: (> total-bridged u0)
  }))

(define-read-only (get-daily-bridge-volume (day uint))
  (default-to u0 (map-get? daily-bridge-volume day)))

;; Admin Functions  
(define-public (set-paused (paused bool))
 (begin
   (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
   (ok (var-set is-paused paused))))

(define-public (set-minimum-amount (amount uint))
 (begin 
   (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
   (asserts! (> amount u0) ERR_INVALID_AMOUNT)
   (ok (var-set min-amount amount))))

(define-public (transfer-ownership (new-owner principal))
 (begin
   (asserts! (is-contract-owner) ERR_UNAUTHORIZED) 
   (asserts! (not (is-eq new-owner tx-sender)) ERR_INVALID_OPERATION)
   (ok (var-set contract-owner new-owner))))

;; Initialize contract
(begin
 (map-set balances tx-sender u1000000000)
 (ok true))