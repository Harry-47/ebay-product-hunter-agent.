# Products evaluated on 2026-11-04 (from data/notes/2026-11-04_hunt_notes.txt). Dot-sourced by tools/build_manual_workbook.ps1.
# Keys omitted = UNKNOWN in the workbook. ASCII only.
function Merge-H($a, $b) { foreach ($k in $b.Keys) { $a[$k] = $b[$k] }; return $a }
function GD($id, $name, $cost, $stock, $ebay, $ref, $rule, $seen, $limit, $q, $seas = 'evergreen', $tgt = 'NONE', $extra = @{}) {
    Rec (Merge-H @{ id = $id; cat = 'REJECTED'; kind = 'gd'; name = $name; cost = $cost; costNote = "Go Dropship price $cost (+5% buying fee added by the calculation)"; stock = "$stock (UK)"; ebayPrice = $ebay; refNote = $ref
            seasonality = $seas; target = $tgt; compliance = 'COMPLIANCE_REVIEW'; failedRule = $rule; seen = $seen; limit = $limit; searchQ = $q; mayChange = 'yes'; status = 'WATCH' } $extra)
}
function ZK($id, $name, $rule, $seen, $limit, $extra = @{}) {
    Rec (Merge-H @{ id = $id; cat = 'REJECTED'; kind = 'none'; name = $name; seasonality = 'evergreen'; target = 'NONE'; failedRule = $rule; seen = $seen; limit = $limit; mayChange = 'yes'; status = 'REJECTED' } $extra)
}

# ---------------- SELECTED ----------------
Rec @{ id = 'AX-20261104-01'; cat = 'SELECTED'; kind = 'ali'; name = 'Orthotic arch support insoles, flatfoot (item 1005006994544777)'; srcUrl = 'https://www.aliexpress.com/item/1005006994544777.html'
    cost = 1.40; costNote = 'SKU S (EU35-40) 1.27, L (EU41-45) 1.29; AliPrice 3-month chart high 1.40 used (conservative); +4% FX added'; stock = 'S 276 / L 185'; delivery = '9 - 12 Nov (Choice, free shipping)'; rating = '4.9 (6,300 reviews)'
    srcSales = '50,000+ sold (Choice)'; srcSeller = 'store 100% positive, 5,000+ sales'; seller = 'we-sell-genuine'; ebayPrice = 7.99
    refNote = 'Reference we-sell-genuine (65,291 feedback) 7.99 free delivery, 62 sales/30d, 10,417 total; best seller greatideasuk 9.95 (313/30d) would give a higher profit; most sellers list 4.25-6.99'
    fvf = 'hb'; str = '3726%'; strSource = 'ZIK'; s50 = 'more than 40: greatideasuk 313, Clickzio 312, 2015ukummeh 241, healthcare-outlet 203, ub5658 190, we-sell-genuine 92 + 62'
    s500 = '15+: central-supplies-limited 66431, pro-11-wellbeing 25833, healthcare-outlet 18321, we-sell-genuine 10417, 2015ukummeh 9594'; listings = '2,200+ eBay UK Buy It Now results'
    variations = '2 sizes (S, L)'; seasonality = 'evergreen'; target = 'NONE'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (provisional, hand calculation)'; status = 'QUALIFIED'; trend = 'Steady evergreen demand'; searchQ = 'orthotic insoles arch support'
    notes = 'List without health claims (plantar fasciitis wording is a compliance risk); sizing returns risk; crowded market. Hand profit at 7.99 about 4.40, margin about 55 percent.' }
Rec @{ id = 'GD-20261104-02'; cat = 'SELECTED'; kind = 'gd'; name = '8 pcs anti slip rug grippers tape, black (HOM-53464)'; srcUrl = 'https://www.godropship.co.uk/8-pcs-anti-slip-soft-mat-rug-carpet-anti-curling-rug-grippers-tape-floor-stickers---black-59756'
    cost = 3.56; costNote = 'Go Dropship price 3.56 (+5% buying fee added by the calculation); price updated 13 Apr 2026 (stable 6+ months)'; stock = '502 (UK)'; delivery = 'Royal Mail Large Letter 3-7 business days, no full tracking (allowed under about 10)'; rating = 'not shown'
    srcSales = 'Household Supplies Bestselling page 1 (4 Nov)'; srcSeller = 'Go Dropship UK warehouse'; seller = 'greatideasuk'; ebayPrice = 6.99
    refNote = 'Reference greatideasuk (310,103 feedback) corner rug grippers 6.99, 207 sales/30d, 29,018 total; same type sold by others at 1.71-3.00'
    fvf = 'home'; str = '1383%'; strSource = 'ZIK'; s50 = '20+: greatideasuk 207, 77karima0000 80, bek-fix 64, householdfurnis 59, moneycruncher 59'
    s500 = '6+: greatideasuk 29018, householdfurnis 4111, 786traders 3987, moneycruncher 3709'; listings = '100 (ZIK)'; variations = '2 colour options'; seasonality = 'evergreen'; target = 'NONE'
    compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (provisional, thin)'; status = 'QUALIFIED'; trend = 'Steady evergreen demand; price war at the low end'; searchQ = 'rug grippers anti slip carpet'
    notes = '57 g parcel. Price war: cheaper identical listings 1.71-3.00; 6.99 depends on greatideasuk following. Hand profit about 1.49, margin about 21 percent, ROI about 40 percent, minimum listing price about 6.39.' }
Rec @{ id = 'GD-20261104-03'; cat = 'SELECTED'; kind = 'gd'; name = 'Wall mounted door stopper, satin stainless steel chrome rubber (HOM-74542)'; srcUrl = 'https://www.godropship.co.uk/wall-mounted-door-stopper-satin-stainless-steel-chrome-rubber-door-stop-61395'
    cost = 3.45; costNote = 'Go Dropship price 3.45 (+5% buying fee added by the calculation); price updated 13 Apr 2026'; stock = '902 (UK)'; delivery = 'Royal Mail Large Letter 3-7 business days, no full tracking (allowed under about 10)'; rating = 'not shown'
    srcSales = 'Household Supplies Bestselling page 1 (4 Nov)'; srcSeller = 'Go Dropship UK warehouse'; seller = 'print_direct247'; ebayPrice = 6.99
    refNote = 'Reference print_direct247 (40,539 feedback) projection chrome door stop 6.99, 78 sales/30d, 11,616 total (closest similar); exact-title sellers 5.58 (awauk72) to 6.40 (mahi.shine077 28/30d)'
    fvf = 'home'; str = '792%'; strSource = 'ZIK'; s50 = '5: ace-bargains1 105, print_direct247 78, usmankhanstore 42, ammarxp100 33, muha_7575 31'
    s500 = '4+: print_direct247 11616 and 8276, panuk31 3540, ace-bargains1 698'; listings = '100 (ZIK)'; variations = 'none'; seasonality = 'evergreen'; target = 'NONE'
    compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (provisional, THIN)'; status = 'QUALIFIED'; trend = 'Steady evergreen demand; price war'; searchQ = 'wall mounted door stopper'
    notes = '86 g parcel. THIN: hand profit about 1.61 at 6.99 but about 1.13 at the exact-title 6.40; minimum listing price about 6.24. print_direct247 also lists the same type at 2.98-2.99.' }
Rec @{ id = 'AX-20261104-04'; cat = 'SELECTED'; kind = 'ali'; name = 'Waterproof bicycle gear raincover, grey 1pc (item 1005006727714509)'; srcUrl = 'https://www.aliexpress.com/item/1005006727714509.html'
    cost = 2.91; costNote = 'SKU Grey 1pcs 2.91 (SuperDeals ignored per user rule); AliPrice chart 1.61 -> 2.91 (rising); +4% FX added'; stock = '20 (Grey 1pcs; 2pcs 6)'; delivery = '9 - 12 Nov (Choice, free shipping)'; rating = '4.9 (1,258 reviews)'
    srcSales = '5,000+ sold (Choice)'; srcSeller = 'store 100% positive, 900+ sales'; seller = 'sa-825109'; ebayPrice = 9.49
    refNote = 'Reference sa-825109 (1,452 feedback) universal bicycle cover 9.49, 27 sales/30d, 119 total; most sellers list the same type at 3.19-4.99; 9.89 sellers list a heavier 1/2-bike cover'
    fvf = 'home'; str = '1368%'; strSource = 'ZIK'; s50 = '10+: moneycruncher 172, wkd-deals 167, eglobalshopltd 135, khalid.mirpur1 72, neverland_cover 72'
    s500 = '6+: neverland_cover 10717, wkd-deals 2048, eglobalshopltd 1641, moneycruncher 1471, fyang003 1276'; listings = '100 (ZIK)'; variations = '1 usable variant (Grey 1pcs)'; seasonality = 'evergreen'; target = 'NONE'
    compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (provisional, FLAGGED)'; status = 'QUALIFIED'; trend = 'Steady demand; low-price race'; searchQ = 'waterproof bike cover'
    notes = 'Flags: stock exactly at the minimum 20; price war (identical listings 3.19-4.99); AliExpress price up 80 percent in 3 months. Hand profit about 4.0 at 9.49.' }
Rec @{ id = 'AX-20261104-05'; cat = 'SELECTED'; kind = 'ali'; name = 'Motion sensor LED night light strip (item 1005006860874836)'; srcUrl = 'https://www.aliexpress.com/item/1005006860874836.html'
    cost = 1.89; costNote = 'SKU warm white 20cm 13LED 1.89 (30cm 2.22, 50cm 2.54, cold white 10cm 1.60); AliPrice one-month high 22.99 NOT used - user decided 4 Nov: SKU price is the cost; +4% FX added'; stock = '253'; delivery = '5 - 8 days (Choice)'; rating = '4.9 (28,400 reviews)'
    srcSales = 'Choice'; srcSeller = 'store 100% positive'; seller = 'jawad_16'; ebayPrice = 4.65; refNote = 'Reference jawad_16 strip light 4.65 (312/30d); ZIK data read 24 Oct'
    fvf = 'home'; str = '2866%'; strSource = 'ZIK (24 Oct)'; s50 = 'ar794256 312, jawad_16 312, trgf04 202, shopvorauk31 189'
    s500 = 'jawad_16 2664, deal_hunterx 1416, shopvorauk31 1036, foundu10016 757, busi42 621, moneycruncher 596, shm-93 523'; variations = '3 lengths (20/30/50cm)'
    seasonality = 'evergreen'; target = 'NONE'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS - user-directed 4 Nov (cost basis)'; status = 'QUALIFIED'; trend = 'Steady evergreen demand'; searchQ = 'usb rechargeable motion sensor night light'
    notes = 'Seller counts and stock read 24 Oct; recheck before listing. Battery/electrical compliance risk (UKCA/CE). Thin margin; under 8 so the 1 pound profit rule applies. Hand profit about 1.35 (buffer 1.24).' }

# ---------------- WATCH ----------------
Rec @{ id = 'AX-20261104-06'; cat = 'WATCH'; kind = 'ali'; name = 'Plush hot water bottle cover 2L, 15 colours (item 1005008227065599)'; srcUrl = 'https://www.aliexpress.com/item/1005008227065599.html'
    cost = 3.54; costNote = 'SKU 1.99 is a one-time offer (max 1 per shopper); struck-through baseline 3.54 used'; stock = 'knitted colours 173-255; plain colours 1-180'; delivery = '9 - 12 Nov (Choice, free shipping)'; rating = '4.3 (186 reviews)'
    srcSales = '1,000+ sold (Choice)'; srcSeller = 'store 95% positive'; seller = 'unknown'; ebayPrice = 6.75; refNote = 'eBay fluffy cover 2L hot water bottle 6.75 (316/30d, Product Explorer); not matched exactly'
    fvf = 'home'; variations = '15 colours'; seasonality = 'winter'; target = 'UK Winter Season'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'WATCH - cover only or bottle included not confirmed'; failedRule = 'variations'
    seen = 'cover-only vs bottle included UNKNOWN; reviews mention missing bottle; one-time offer price'; limit = 'confirmed product contents and repeatable cost'; reason = 'Reviews say missing bottle; price is a one-time offer'; mayChange = 'yes'; status = 'WATCH'; searchQ = 'hot water bottle fluffy cover 2 litre'
    notes = 'Hot water bottles also carry a safety-standard (BS 1970) compliance risk.' }

# ---------------- REJECTED ----------------
ZK 'AX-20261104-07' 'Electric rechargeable hot water bottle (item 1005008144760827)' 'stock' 'SKU stock 0 / 9 / 0 (SKU 2.40-2.81)' 'stock of 20+ (50+ seasonal)' @{ kind = 'ali'; cost = 2.81; ebayPrice = 13.85; refNote = 'eBay demand passes (224/30d at 13.85); 220V mains plug compliance risk'; seasonality = 'winter'; target = 'UK Winter Season'; searchQ = 'electric rechargeable hot water bottle hand warmer' }
ZK 'AX-20261104-08' 'Rechargeable hand warmer 2-pack' 'profit' 'AliExpress 2-packs from 8.89 against eBay 11-13; no exact 2-pack has 500+ total sold (best 308)' 'profit of at least GBP 1 and 500+ total sold' @{ kind = 'ali'; cost = 8.89; ebayPrice = 11.79; searchQ = 'rechargeable hand warmer'; seasonality = 'winter' }
ZK 'AX-20261104-09' 'Rug grippers (AliExpress 1005008699417921)' 'stock' 'every variant stock 2-9' 'stock of 20+' @{ kind = 'ali'; cost = 1.99; searchQ = 'rug grippers anti slip carpet' }
ZK 'AX-20261104-10' 'Rug grippers 4/8 pcs triangle (AliExpress 1005006860951160)' 'stock' '12 available' 'stock of 20+' @{ kind = 'ali'; cost = 2.44; searchQ = 'rug grippers anti slip carpet' }
ZK 'AX-20261104-11' 'TV wall bracket slim (AliExpress Choice)' 'profit' 'cheapest Choice 7.92-9.29 against eBay 7.95' 'profit of at least GBP 1' @{ kind = 'ali'; cost = 7.92; ebayPrice = 7.95; seller = 'print_direct247'; searchQ = 'tv wall bracket mount slim' }
ZK 'AX-20261104-12' 'UPVC Espag key-locking window handle' 'demand' 'AliExpress Choice key-locking handle 57 sold (the 1K+ items are child safety locks)' 'Choice and 500+ sold' @{ kind = 'ali'; ebayPrice = 9.99; searchQ = 'upvc window handle locking key' }
ZK 'AX-20261104-13' 'Arthritis compression gloves (AliExpress 1005010439217902 and 1005007445331586)' 'variations' 'S/M/L/XL sizes in 2-4 colours; one size S stock 13' 'no sized clothing; max 2-3 variations; stock 20+' @{ kind = 'ali'; cost = 1.56; ebayPrice = 6.95; seller = 'greatideasuk'; refNote = 'eBay market 2.95-6.95; greatideasuk 96/30d at 6.95'; searchQ = 'arthritis compression gloves' }
ZK 'ZK-20261104-14' 'Disposable hotel spa slippers' 'strong_sellers' '197 sold in 30 days; only 1 seller at 30+/30d' '3+ sellers with 30+/30d' @{ str = '197%'; strSource = 'ZIK'; s50 = '1' }
ZK 'ZK-20261104-15' 'Precision tweezers set 6 pcs' 'demand' '96 sold in 30 days, average 3.32, top seller 8/30d' '3+ sellers with 30+/30d' @{ str = '96%'; strSource = 'ZIK'; s50 = '0' }
ZK 'ZK-20261104-16' 'Glasses repair screws and nuts kit' 'demand' '60 sold in 30 days, average 4.84, top seller 18/30d' '3+ sellers with 30+/30d' @{ str = '60%'; strSource = 'ZIK'; s50 = '0' }
ZK 'ZK-20261104-17' 'Collapsible waste water hose (caravan)' 'demand' '44 sold in 30 days' '3+ sellers with 30+/30d' @{ str = '151.72%'; strSource = 'ZIK'; s50 = '0' }
GD 'GD-20261104-18' 'Large natural suede car cleaning cloth' 4.45 622 4.99 'ukdepot22 chamois cloth 4.99 (143/30d)' 'profit' 'eBay 4.99 against landed cost about 4.67 plus fees' 'profit of at least GBP 1' 'suede car cleaning cloth drying towel'
GD 'GD-20261104-19' 'Waterproof junction box connector 2-core / 3-core' 3.24 2143 2.45 'eBay 2.35-2.45' 'price' 'eBay 2.35-2.45 against cost 3.24' 'profit of at least GBP 1' 'waterproof junction box connector outdoor'
GD 'GD-20261104-20' '2pcs replacement 360 spin mop heads' 4.29 664 7.99 'eBay 5-pack Vileda-compatible 7.99; no clean 2-pack match' 'brand' 'eBay listings are Vileda-compatible multipacks (brand name)' 'no brand-name matching; like-for-like pack' '360 spin mop head replacement microfibre'
GD 'GD-20261104-21' '6m rubber seal weather strip foam (draught)' 5.52 876 4.05 'the-daily-foundry 4.05 (542/30d), moneycruncher 3.79 (511/30d)' 'price' 'eBay 3.79-4.05 against cost 5.52' 'profit of at least GBP 1' 'door window draught excluder foam seal strip' 'winter' 'UK Winter Season'

# Extra Summary rows
$script:SUMX = @(
    , @('Sources used', 'AliExpress UK, Go Dropship UK, ZIK Analytics, eBay UK', 'AW Dropship skipped (not signed in, user said skip); Amazon UK not run')
    , @('Rule changes today', 'Strong sellers: 3+ top-20 sellers with 30+ sales in 30 days AND 2+ with 500+ total sold; user decision: SKU price is the cost even when AliPrice shows a spike', 'logged in the CLAUDE.md change log')
    , @('How found', 'Competitor store scans in ZIK (greatideasuk, we-sell-genuine, print_direct247, cardys, e-gofly) and the posture corrector analysis, then AliExpress and Go Dropship checks', 'Posture corrector market analysed first at the user request')
    , @('Open items', 'Night light seller counts and stock are from 24 Oct; plush hot water bottle cover is WATCH (contents unclear); passes 2 to 4 are thin or flagged', 'all five passes are hand-calculated provisional passes')
    , @('Not done', 'Amazon UK not run; 15-a-day target and 35-per-source budgets not reached', 'only 5 passes found')
)
