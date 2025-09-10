;; Airdrop Distribution Contract
;; This contract handles token airdrop distribution with various safety checks and features

;; Define SIP-010 Fungible Token trait
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

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-CLAIMED (err u101))
(define-constant ERR-NOT-ELIGIBLE (err u102))
(define-constant ERR-WRONG-AMOUNT (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-AIRDROP-INACTIVE (err u105))
(define-constant ERR-TOKEN-NOT-SET (err u106))
(define-constant ERR-INVALID-TOKEN (err u107))
(define-constant ERR-INVALID-AMOUNT (err u108))
(define-constant ERR-INVALID-PERIOD (err u109))
(define-constant ERR-INVALID-ADDRESS (err u110))

;; Constants for validation
(define-constant MAX-AIRDROP-AMOUNT u1000000000)
(define-constant MIN-CLAIM-AMOUNT u1)
(define-constant MAX-CLAIM-PERIOD u10000)
(define-constant CONTRACT-ADDRESS (as-contract tx-sender))

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var total-airdrop-amount uint u0)
(define-data-var airdrop-active bool true)
(define-data-var claim-period-end uint u0)
(define-data-var tokens-per-claim uint u0)
(define-data-var token-contract (optional principal) none)

;; Data Maps
(define-map eligible-addresses principal uint)
(define-map claimed-amounts principal uint)
(define-map whitelist principal bool)
(define-map valid-tokens principal bool)

;; Private validation functions
(define-private (validate-amount (amount uint))
    (and 
        (>= amount MIN-CLAIM-AMOUNT)
        (<= amount MAX-AIRDROP-AMOUNT)
    )
)

(define-private (validate-period (period uint))
    (<= period MAX-CLAIM-PERIOD)
)

(define-private (validate-address (address principal))
    (and
        (not (is-eq address CONTRACT-ADDRESS))
        (not (is-eq address (var-get contract-owner)))
    )
)

(define-private (is-valid-token (token principal))
    (default-to false (map-get? valid-tokens token))
)

(define-private (validate-token (token <ft-trait>))
    (let ((token-principal (contract-of token)))
        (and 
            (is-valid-token token-principal)
            (match (contract-call? token get-name)
                success true
                error false)
        )
    )
)

;; Read-only functions
(define-read-only (get-claim-status (address principal))
    (default-to u0 (map-get? claimed-amounts address))
)

(define-read-only (get-token-contract)
    (var-get token-contract)
)

(define-read-only (is-eligible (address principal))
    (is-some (map-get? eligible-addresses address))
)

(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

(define-read-only (is-whitelisted (address principal))
    (default-to false (map-get? whitelist address))
)

(define-read-only (get-airdrop-info)
    (ok {
        total-amount: (var-get total-airdrop-amount),
        is-active: (var-get airdrop-active),
        claim-end: (var-get claim-period-end),
        amount-per-claim: (var-get tokens-per-claim)
    })
)

;; Private functions
(define-private (check-eligibility (address principal))
    (and 
        (is-eligible address)
        (< (get-claim-status address) (default-to u0 (map-get? eligible-addresses address)))
        (var-get airdrop-active)
        (<= block-height (var-get claim-period-end))
    )
)

;; Public functions
(define-public (set-token-contract (token <ft-trait>))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (match (contract-call? token get-name)
                    success true
                    error false) ERR-INVALID-TOKEN)
        (let ((token-principal (contract-of token)))
            (map-set valid-tokens token-principal true)
            (var-set token-contract (some token-principal))
            (ok true)
        )
    )
)

(define-public (initialize-airdrop (total-amount uint) (per-claim uint) (period uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (validate-amount total-amount) ERR-INVALID-AMOUNT)
        (asserts! (validate-amount per-claim) ERR-INVALID-AMOUNT)
        (asserts! (validate-period period) ERR-INVALID-PERIOD)
        (asserts! (>= total-amount per-claim) ERR-INVALID-AMOUNT)
        
        (var-set total-airdrop-amount total-amount)
        (var-set tokens-per-claim per-claim)
        (var-set claim-period-end (+ block-height period))
        (var-set airdrop-active true)
        (ok true)
    )
)

(define-public (add-to-whitelist (address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (validate-address address) ERR-INVALID-ADDRESS)
        (asserts! (not (is-whitelisted address)) ERR-ALREADY-CLAIMED)
        (map-set whitelist address true)
        (ok true)
    )
)

(define-public (remove-from-whitelist (address principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (validate-address address) ERR-INVALID-ADDRESS)
        (asserts! (is-whitelisted address) ERR-NOT-ELIGIBLE)
        (map-delete whitelist address)
        (ok true)
    )
)

(define-public (set-eligible-amount (address principal) (amount uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (validate-address address) ERR-INVALID-ADDRESS)
        (asserts! (validate-amount amount) ERR-INVALID-AMOUNT)
        (map-set eligible-addresses address amount)
        (ok true)
    )
)

(define-public (claim-airdrop (ft <ft-trait>))
    (let (
        (caller tx-sender)
        (eligible-amount (default-to u0 (map-get? eligible-addresses caller)))
        (claimed-amount (get-claim-status caller))
        (token (unwrap! (var-get token-contract) ERR-TOKEN-NOT-SET))
    )
        (asserts! (validate-address caller) ERR-INVALID-ADDRESS)
        (asserts! (validate-token ft) ERR-INVALID-TOKEN)
        (asserts! (is-eq token (contract-of ft)) ERR-INVALID-TOKEN)
        (asserts! (check-eligibility caller) ERR-NOT-ELIGIBLE)
        (asserts! (>= (- eligible-amount claimed-amount) (var-get tokens-per-claim)) ERR-INSUFFICIENT-BALANCE)
        
        ;; Update claimed amount
        (map-set claimed-amounts caller (+ claimed-amount (var-get tokens-per-claim)))
        
        ;; Transfer tokens using ft-trait
        (as-contract
            (contract-call? ft transfer
                (var-get tokens-per-claim)
                tx-sender
                caller
                none
            )
        )
    )
)

(define-public (end-airdrop)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set airdrop-active false)
        (ok true)
    )
)

;; Emergency functions
(define-public (update-claim-period (new-end uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (validate-period (- new-end block-height)) ERR-INVALID-PERIOD)
        (var-set claim-period-end new-end)
        (ok true)
    )
)

(define-public (emergency-withdraw (ft <ft-trait>) (amount uint))
    (let ((token (unwrap! (var-get token-contract) ERR-TOKEN-NOT-SET)))
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (validate-amount amount) ERR-INVALID-AMOUNT)
        (asserts! (validate-token ft) ERR-INVALID-TOKEN)
        (asserts! (is-eq (contract-of ft) token) ERR-INVALID-TOKEN)
        (as-contract
            (contract-call? ft transfer
                amount
                tx-sender
                (var-get contract-owner)
                none
            )
        )
    )
)