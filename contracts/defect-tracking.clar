;; Defect Tracking Contract
;; Records identified issues and resolutions

(define-data-var admin principal tx-sender)

;; Defect severity: 0 = minor, 1 = major, 2 = critical
;; Defect status: 0 = open, 1 = in-progress, 2 = resolved, 3 = closed
(define-map defects
  { defect-id: (string-ascii 32) }
  {
    product-id: (string-ascii 32),
    reporter: principal,
    description: (string-ascii 256),
    severity: uint,
    status: uint,
    reported-at: uint,
    resolution: (optional (string-ascii 256))
  }
)

(define-read-only (get-defect (defect-id (string-ascii 32)))
  (map-get? defects { defect-id: defect-id })
)

(define-public (report-defect
    (defect-id (string-ascii 32))
    (product-id (string-ascii 32))
    (description (string-ascii 256))
    (severity uint))
  (let
    ((caller tx-sender))
    (asserts! (is-none (get-defect defect-id)) (err u1)) ;; Defect ID already exists
    (asserts! (< severity u3) (err u2)) ;; Invalid severity level

    (ok (map-set defects
      { defect-id: defect-id }
      {
        product-id: product-id,
        reporter: caller,
        description: description,
        severity: severity,
        status: u0, ;; open status
        reported-at: block-height,
        resolution: none
      }
    ))
  )
)

(define-public (update-defect-status
    (defect-id (string-ascii 32))
    (new-status uint))
  (let
    ((defect (unwrap! (get-defect defect-id) (err u3)))) ;; Defect not found
    (asserts! (< new-status u4) (err u4)) ;; Invalid status value

    (ok (map-set defects
      { defect-id: defect-id }
      (merge defect { status: new-status })
    ))
  )
)

(define-public (resolve-defect
    (defect-id (string-ascii 32))
    (resolution (string-ascii 256)))
  (let
    ((defect (unwrap! (get-defect defect-id) (err u3)))) ;; Defect not found

    (ok (map-set defects
      { defect-id: defect-id }
      (merge defect {
        status: u2, ;; resolved status
        resolution: (some resolution)
      })
    ))
  )
)

(define-public (close-defect (defect-id (string-ascii 32)))
  (let
    ((defect (unwrap! (get-defect defect-id) (err u3)))) ;; Defect not found
    (asserts! (is-eq (get status defect) u2) (err u5)) ;; Defect must be resolved first

    (ok (map-set defects
      { defect-id: defect-id }
      (merge defect { status: u3 }) ;; closed status
    ))
  )
)
