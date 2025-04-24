;; Facility Verification Contract
;; Validates legitimate production sites

(define-data-var admin principal tx-sender)

;; Facility status: 0 = pending, 1 = verified, 2 = suspended
(define-map facilities
  { facility-id: (string-ascii 32) }
  {
    owner: principal,
    name: (string-ascii 64),
    location: (string-ascii 128),
    status: uint,
    registration-date: uint
  }
)

(define-read-only (get-facility (facility-id (string-ascii 32)))
  (map-get? facilities { facility-id: facility-id })
)

(define-public (register-facility
    (facility-id (string-ascii 32))
    (name (string-ascii 64))
    (location (string-ascii 128)))
  (let
    ((caller tx-sender))
    (asserts! (is-none (get-facility facility-id)) (err u1)) ;; Facility ID already exists
    (ok (map-set facilities
      { facility-id: facility-id }
      {
        owner: caller,
        name: name,
        location: location,
        status: u0, ;; pending status
        registration-date: block-height
      }
    ))
  )
)

(define-public (verify-facility (facility-id (string-ascii 32)))
  (let
    ((facility (unwrap! (get-facility facility-id) (err u2)))) ;; Facility not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (ok (map-set facilities
      { facility-id: facility-id }
      (merge facility { status: u1 }) ;; Set to verified
    ))
  )
)

(define-public (suspend-facility (facility-id (string-ascii 32)))
  (let
    ((facility (unwrap! (get-facility facility-id) (err u2)))) ;; Facility not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (ok (map-set facilities
      { facility-id: facility-id }
      (merge facility { status: u2 }) ;; Set to suspended
    ))
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (ok (var-set admin new-admin))
  )
)
