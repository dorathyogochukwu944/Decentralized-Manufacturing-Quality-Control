;; Certification Contract
;; Manages final approval for distribution

(define-data-var admin principal tx-sender)

;; Certification status: 0 = pending, 1 = approved, 2 = rejected, 3 = revoked
(define-map certifications
  { product-id: (string-ascii 32) }
  {
    certifier: principal,
    status: uint,
    certification-date: uint,
    expiration-date: (optional uint),
    notes: (string-ascii 256)
  }
)

(define-read-only (get-certification (product-id (string-ascii 32)))
  (map-get? certifications { product-id: product-id })
)

(define-public (request-certification (product-id (string-ascii 32)))
  (let
    ((caller tx-sender))
    (asserts! (is-none (get-certification product-id)) (err u1)) ;; Certification already exists

    (ok (map-set certifications
      { product-id: product-id }
      {
        certifier: caller,
        status: u0, ;; pending status
        certification-date: block-height,
        expiration-date: none,
        notes: ""
      }
    ))
  )
)

(define-public (approve-certification
    (product-id (string-ascii 32))
    (expiration-blocks (optional uint))
    (notes (string-ascii 256)))
  (let
    ((certification (unwrap! (get-certification product-id) (err u2)))) ;; Certification not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized

    (ok (map-set certifications
      { product-id: product-id }
      {
        certifier: (get certifier certification),
        status: u1, ;; approved status
        certification-date: block-height,
        expiration-date: expiration-blocks,
        notes: notes
      }
    ))
  )
)

(define-public (reject-certification
    (product-id (string-ascii 32))
    (notes (string-ascii 256)))
  (let
    ((certification (unwrap! (get-certification product-id) (err u2)))) ;; Certification not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized

    (ok (map-set certifications
      { product-id: product-id }
      {
        certifier: (get certifier certification),
        status: u2, ;; rejected status
        certification-date: (get certification-date certification),
        expiration-date: none,
        notes: notes
      }
    ))
  )
)

(define-public (revoke-certification
    (product-id (string-ascii 32))
    (notes (string-ascii 256)))
  (let
    ((certification (unwrap! (get-certification product-id) (err u2)))) ;; Certification not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (asserts! (is-eq (get status certification) u1) (err u4)) ;; Certification not approved

    (ok (map-set certifications
      { product-id: product-id }
      {
        certifier: (get certifier certification),
        status: u3, ;; revoked status
        certification-date: (get certification-date certification),
        expiration-date: none,
        notes: notes
      }
    ))
  )
)

(define-read-only (is-certification-valid (product-id (string-ascii 32)))
  (let
    ((certification (unwrap! (get-certification product-id) false)))
    (and
      (is-eq (get status certification) u1) ;; approved status
      (match (get expiration-date certification)
        expiry (< block-height expiry)
        true
      )
    )
  )
)
