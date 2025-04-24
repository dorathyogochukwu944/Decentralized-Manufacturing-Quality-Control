;; Testing Protocol Contract
;; Manages quality assurance procedures

(define-data-var admin principal tx-sender)

;; Protocol status: 0 = draft, 1 = active, 2 = deprecated
(define-map protocols
  { protocol-id: (string-ascii 32) }
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    status: uint,
    created-at: uint,
    created-by: principal
  }
)

;; Test result: 0 = pending, 1 = passed, 2 = failed
(define-map test-results
  { product-id: (string-ascii 32), protocol-id: (string-ascii 32) }
  {
    tester: principal,
    result: uint,
    notes: (string-ascii 256),
    tested-at: uint
  }
)

(define-read-only (get-protocol (protocol-id (string-ascii 32)))
  (map-get? protocols { protocol-id: protocol-id })
)

(define-read-only (get-test-result (product-id (string-ascii 32)) (protocol-id (string-ascii 32)))
  (map-get? test-results { product-id: product-id, protocol-id: protocol-id })
)

(define-public (create-protocol
    (protocol-id (string-ascii 32))
    (name (string-ascii 64))
    (description (string-ascii 256)))
  (let
    ((caller tx-sender))
    (asserts! (is-none (get-protocol protocol-id)) (err u1)) ;; Protocol ID already exists
    (ok (map-set protocols
      { protocol-id: protocol-id }
      {
        name: name,
        description: description,
        status: u0, ;; draft status
        created-at: block-height,
        created-by: caller
      }
    ))
  )
)

(define-public (activate-protocol (protocol-id (string-ascii 32)))
  (let
    ((protocol (unwrap! (get-protocol protocol-id) (err u2)))) ;; Protocol not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (ok (map-set protocols
      { protocol-id: protocol-id }
      (merge protocol { status: u1 }) ;; Set to active
    ))
  )
)

(define-public (deprecate-protocol (protocol-id (string-ascii 32)))
  (let
    ((protocol (unwrap! (get-protocol protocol-id) (err u2)))) ;; Protocol not found
    (asserts! (is-eq tx-sender (var-get admin)) (err u3)) ;; Not authorized
    (ok (map-set protocols
      { protocol-id: protocol-id }
      (merge protocol { status: u2 }) ;; Set to deprecated
    ))
  )
)

(define-public (record-test-result
    (product-id (string-ascii 32))
    (protocol-id (string-ascii 32))
    (result uint)
    (notes (string-ascii 256)))
  (let
    ((caller tx-sender)
     (protocol (unwrap! (get-protocol protocol-id) (err u2)))) ;; Protocol not found

    (asserts! (is-eq (get status protocol) u1) (err u4)) ;; Protocol not active
    (asserts! (or (is-eq result u1) (is-eq result u2)) (err u5)) ;; Invalid result value

    (ok (map-set test-results
      { product-id: product-id, protocol-id: protocol-id }
      {
        tester: caller,
        result: result,
        notes: notes,
        tested-at: block-height
      }
    ))
  )
)
