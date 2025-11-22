;; =============================================
;; token-vesting-locker
;; A minimal and secure vesting contract
;; =============================================

;; Added SIP-010 trait definition for standard token interactions
(define-trait sip-010-trait
  (
    ;; SIP010 transfer signature: (transfer (recipient sender amount memo))
    (transfer (principal principal uint (optional (buff 34))) (response bool uint))
    (get-name () (response (string-ascii 32) uint))
    (get-symbol () (response (string-ascii 32) uint))
    (get-decimals () (response uint uint))
    (get-balance (principal) (response uint uint))
    (get-total-supply () (response uint uint))
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

(define-data-var admin principal tx-sender)
(define-data-var token-contract principal 'SP000000000000000000002Q6VF78.token)

(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-SCHEDULE-NOT-FOUND u101)
(define-constant ERR-NOTHING-TO-CLAIM u102)
(define-constant ERR-NOT-BENEFICIARY u103)
(define-constant ERR-ALREADY-EXISTS u104)
(define-constant ERR-TOO-EARLY u105)

(define-data-var schedule-id uint u0)

(define-map vesting-schedules
  { id: uint }
  {
    beneficiary: principal,
    amount: uint,
    start-height: uint,
    end-height: uint,
    claimed: uint,
    active: bool
  }
)

;; -----------------------------
;; Helpers
;; -----------------------------
(define-read-only (is-admin)
  (is-eq tx-sender (var-get admin))
)

(define-read-only (get-unlocked (id uint))
  ;; Fixed unwrap! to return response type and removed invalid unwrap call
  (let ((sched (unwrap! (map-get? vesting-schedules { id: id })
                        (err ERR-SCHEDULE-NOT-FOUND))))
    (let ((now burn-block-height))
      (if (< now (get start-height sched))
          (ok u0)
          (if (>= now (get end-height sched))
              (ok (get amount sched))
              (let (
                    (duration (- (get end-height sched) (get start-height sched)))
                    (elapsed (- now (get start-height sched)))
                   )
                (ok (/ (* (get amount sched) elapsed) duration))
              )
          )
      )
    )
  )
)

;; -----------------------------
;; Admin Functions
;; -----------------------------
(define-public (set-token-contract (contract principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set token-contract contract)
    (ok true)
  )
)

(define-public (create-schedule
    (beneficiary principal)
    (amount uint)
    (start uint)
    (end uint)
  )
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set schedule-id (+ u1 (var-get schedule-id)))

    (map-set vesting-schedules
      { id: (var-get schedule-id) }
      {
        beneficiary: beneficiary,
        amount: amount,
        start-height: start,
        end-height: end,
        claimed: u0,
        active: true
      }
    )

    (ok (var-get schedule-id))
  )
)

(define-public (cancel-schedule (id uint))
  (let ((sched (unwrap! (map-get? vesting-schedules { id: id })
                        (err ERR-SCHEDULE-NOT-FOUND))))
    (begin
      (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
      (map-set vesting-schedules { id: id } (merge sched { active: false }))
      (ok true)
    )
  )
)

;; -----------------------------
;; Claim Function
;; -----------------------------
;; Updated signature to accept token-trait for dynamic contract calls
(define-public (claim (id uint) (token-trait <sip-010-trait>))
  (let ((sched (unwrap! (map-get? vesting-schedules { id: id })
                        (err ERR-SCHEDULE-NOT-FOUND))))
    (begin
      ;; Ensure the passed trait matches the configured token
      (asserts! (is-eq (contract-of token-trait) (var-get token-contract)) (err ERR-NOT-AUTHORIZED))
      ;; Ensure schedule is active and caller is beneficiary
      (asserts! (get active sched) (err ERR-SCHEDULE-NOT-FOUND))
      (asserts! (is-eq tx-sender (get beneficiary sched)) (err ERR-NOT-BENEFICIARY))

      (let (
             (unlocked (try! (get-unlocked id)))
             (available (- unlocked (get claimed sched)))
           )
        (if (<= available u0)
            (err ERR-NOTHING-TO-CLAIM)
            (let (
                   ;; SIP-010 transfer(recipient sender amount memo)
                   (transfer-result (as-contract (contract-call? token-trait transfer (get beneficiary sched) tx-sender available none)))
                 )
              (match transfer-result
                ok-val
                  (begin
                    (map-set vesting-schedules { id: id }
                             (merge sched { claimed: (+ (get claimed sched) available) }))
                    (ok true)
                  )
                err-val (err err-val))
            )
        )
      )
    )
  )
)
