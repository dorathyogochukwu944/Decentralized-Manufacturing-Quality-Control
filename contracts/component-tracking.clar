;; Component Tracking Contract
;; Records parts used in assembly

(define-data-var admin principal tx-sender)

;; Component status: 0 = registered, 1 = in-use, 2 = defective, 3 = retired
(define-map components
  { component-id: (string-ascii 32) }
  {
    manufacturer: principal,
    name: (string-ascii 64),
    type: (string-ascii 32),
    status: uint,
    registration-date: uint
  }
)

;; Track which components are used in which products
(define-map product-components
  { product-id: (string-ascii 32), component-id: (string-ascii 32) }
  { added-at: uint }
)

(define-read-only (get-component (component-id (string-ascii 32)))
  (map-get? components { component-id: component-id })
)

(define-read-only (is-component-in-product (product-id (string-ascii 32)) (component-id (string-ascii 32)))
  (is-some (map-get? product-components { product-id: product-id, component-id: component-id }))
)

(define-public (register-component
    (component-id (string-ascii 32))
    (name (string-ascii 64))
    (type (string-ascii 32)))
  (let
    ((caller tx-sender))
    (asserts! (is-none (get-component component-id)) (err u1)) ;; Component ID already exists
    (ok (map-set components
      { component-id: component-id }
      {
        manufacturer: caller,
        name: name,
        type: type,
        status: u0, ;; registered status
        registration-date: block-height
      }
    ))
  )
)

(define-public (add-component-to-product
    (product-id (string-ascii 32))
    (component-id (string-ascii 32)))
  (let
    ((component (unwrap! (get-component component-id) (err u2)))) ;; Component not found
    (asserts! (is-eq (get status component) u0) (err u3)) ;; Component not available
    (asserts! (not (is-component-in-product product-id component-id)) (err u4)) ;; Already added to this product

    ;; Update component status to in-use
    (map-set components
      { component-id: component-id }
      (merge component { status: u1 })
    )

    ;; Add to product-components map
    (ok (map-set product-components
      { product-id: product-id, component-id: component-id }
      { added-at: block-height }
    ))
  )
)

(define-public (mark-component-defective (component-id (string-ascii 32)))
  (let
    ((component (unwrap! (get-component component-id) (err u2)))) ;; Component not found
    (ok (map-set components
      { component-id: component-id }
      (merge component { status: u2 }) ;; Set to defective
    ))
  )
)

(define-public (retire-component (component-id (string-ascii 32)))
  (let
    ((component (unwrap! (get-component component-id) (err u2)))) ;; Component not found
    (ok (map-set components
      { component-id: component-id }
      (merge component { status: u3 }) ;; Set to retired
    ))
  )
)
