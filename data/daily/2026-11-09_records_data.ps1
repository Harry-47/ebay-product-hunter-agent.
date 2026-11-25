# Products evaluated on 2026-11-09 (from data/notes/2026-11-09_hunt_notes.txt). Dot-sourced by tools/build_manual_workbook.ps1.
# Keys omitted = UNKNOWN in the workbook. ASCII only. Sell-through is hand calculated: ZIK sold 30d / eBay UK active (BIN, New, UK).
function Merge-H($a, $b) { foreach ($k in $b.Keys) { $a[$k] = $b[$k] }; return $a }
function GD($id, $name, $cost, $stock, $ebay, $ref, $rule, $seen, $limit, $q, $seas = 'evergreen', $tgt = 'NONE', $extra = @{}) {
    Rec (Merge-H @{ id = $id; cat = 'REJECTED'; kind = 'gd'; name = $name; cost = $cost; costNote = "Go Dropship price $cost (+5% buying fee added by the calculation)"; stock = "$stock (UK)"; ebayPrice = $ebay; refNote = $ref
            seasonality = $seas; target = $tgt; compliance = 'COMPLIANCE_REVIEW'; failedRule = $rule; seen = $seen; limit = $limit; reason = $seen; searchQ = $q; mayChange = 'yes'; status = 'WATCH' } $extra)
}
function AE($id, $name, $cost, $stock, $ebay, $ref, $rule, $seen, $limit, $q, $seas = 'evergreen', $tgt = 'NONE', $extra = @{}) {
    Rec (Merge-H @{ id = $id; cat = 'REJECTED'; kind = 'ali'; name = $name; cost = $cost; costNote = "AliExpress SKU price $cost (+4% FX added)"; stock = "$stock"; ebayPrice = $ebay; refNote = $ref
            seasonality = $seas; target = $tgt; compliance = 'COMPLIANCE_REVIEW'; failedRule = $rule; seen = $seen; limit = $limit; reason = $seen; searchQ = $q; mayChange = 'yes'; status = 'WATCH' } $extra)
}

# ---------------- SELECTED ----------------
Rec @{ id = 'AX-20261109-01'; cat = 'SELECTED'; kind = 'ali'; name = 'Solar candy cane pathway lights 5-piece set, 8 modes (item 1005009755231255)'; srcUrl = 'https://www.aliexpress.com/item/1005009755231255.html'
    cost = 6.14; costNote = 'SKU List 5PC 6.14 (one-time offer label shown, max 1 per shopper); struck 18.66 not used; +4% FX added'; stock = '96 (5PC)'; delivery = '15 - 19 Nov (Choice, free shipping)'; rating = '4.7'
    srcSales = '1,000+ sold (Choice)'; srcSeller = 'Art Lighting World Store, 96.8% positive'; seller = '16a median of 5 lowest solar 5-pack listings'; ebayPrice = 13.12
    refNote = 'Pre-event (16a) reference: median of strivefor_disco 11.41, keyto_happy151 12.78, concentrate_on_ 13.12, colorful_rainbo 14.05, iamzawarmalik 14.40 (pack sizes of 2 not confirmed)'
    fvf = 'gar'; str = 'NOT GATED (16a pre-event)'; strSource = 'ZIK 34 sold/30d (early season)'; s50 = 'not gated (16a pre-event)'; s500 = 'not gated (16a pre-event)'
    seasonality = 'christmas'; target = 'Christmas'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS on ROI (pre-event 16a, provisional)'; status = 'QUALIFIED'
    trend = 'Christmas seasonal, rising'; searchQ = 'solar candy cane lights'; exception = 'margin under 30% (passes on ROI); sales_basis PRE_EVENT'
    notes = 'Profit 3.17, ROI 49.7%, min listing 10.73, buffer profit 2.79. Recheck at Christmas -30 and -14 days. One-time offer price risk.' }
Rec @{ id = 'AX-20261109-02'; cat = 'SELECTED'; kind = 'ali'; name = 'Electric lint remover, LED display, USB rechargeable, Grey (item 1005007097015654)'; srcUrl = 'https://www.aliexpress.com/item/1005007097015654.html'
    cost = 3.69; costNote = 'SKU List Grey 3.69 = page price; struck 7.85 not used; +4% FX added'; stock = '235 (Grey)'; delivery = '14 - 17 Nov (free shipping)'; rating = '4.9 (4,877 reviews)'
    srcSales = '10,000+ sold'; srcSeller = 'Best MorningMan Store, feedback % UNKNOWN'; seller = 'PrimePickMall'; ebayPrice = 8.99
    refNote = 'Reference PrimePickMall 8.99 (40/30d, 1,497 feedback); carmen-l33 8.99 (25/30d)'
    fvf = 'home'; str = '102%'; strSource = 'HAND: ZIK 929 sold / eBay UK 908 active'; s50 = '30+/30d: bright-star9 145, pipestation 67, rafaytraders 67, bizzofrabeel 58, PrimePickMall 40, sabhos 30'
    s500 = 'pipestation 1150, bigmaket 1008, ukdepot22 963, bright-star9 562'; listings = '908 eBay UK Buy It Now results'
    seasonality = 'winter'; target = 'NONE'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (provisional, store feedback UNKNOWN)'; status = 'QUALIFIED'
    trend = 'Steady, winter uplift'; searchQ = 'electric lint remover rechargeable'
    notes = 'Profit 2.81, margin 31.2%, ROI 73.2%, min listing 6.52, buffer 2.58. Check store feedback 90%+ before listing. Rechargeable battery: UKCA/CE.' }
Rec @{ id = 'AX-20261109-03'; cat = 'SELECTED'; kind = 'ali'; name = 'Mini USB rechargeable milk frother 3-speed, Black (item 1005007878387904)'; srcUrl = 'https://www.aliexpress.com/item/1005007878387904.html'
    cost = 3.00; costNote = 'SKU List Black 2.87; cost set to 3.00 = AliPrice 3-month high; max 1 per shopper at this price; struck 9.01 not used; +4% FX added'; stock = '125 (Black)'; delivery = '14 - 17 Nov (free shipping)'; rating = '4.7 (4,043 reviews)'
    srcSales = '10,000+ sold (Choice)'; srcSeller = 'CREATEPRO Store, 97.2% positive'; seller = 'moni-3019'; ebayPrice = 6.30
    refNote = 'Reference moni-3019 Black (most popular variant) 6.30 free P&P, 58/30d, 688 total'
    fvf = 'home'; str = '83%+'; strSource = 'HAND: ZIK 996 sold / eBay UK at most 1,200 active'; s50 = '30+/30d: abuhuish0 328, dailysupplies02 98, ar794256 97, moni-3019 58, spiritual4126 51'
    s500 = 'abuhuish0 970, moni-3019 688, dailysupplies02 588'; listings = '1,000+ (5 pages of 240)'
    seasonality = 'evergreen'; target = 'NONE'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (provisional)'; status = 'QUALIFIED'
    trend = 'Steady evergreen'; searchQ = 'usb rechargeable milk frother'
    notes = 'Profit 1.55, ROI 49.6%, min listing 5.64, buffer 1.36. eBay listing has 2 heads (whisk + frother); AliExpress shows 1 head - check. One-per-shopper price risk.' }
Rec @{ id = 'AX-20261109-04'; cat = 'SELECTED'; kind = 'ali'; name = 'Digital food / meat probe thermometer TP300 (item 1005006824959033)'; srcUrl = 'https://www.aliexpress.com/item/1005006824959033.html'
    cost = 1.42; costNote = 'SKU List 1.26; cost set to 1.42 = AliPrice 3-month high; struck 3.88 not used; +4% FX added'; stock = '1286'; delivery = '14 - 17 Nov (free shipping)'; rating = '4.7 (14,650 reviews)'
    srcSales = '100K+ sold (Choice)'; srcSeller = 'Shop1103378163 Store, 96.0% positive'; seller = 'lupo-store'; ebayPrice = 4.50
    refNote = 'Reference lupo-store 4.50 single, no variations, free RM48, 201/30d, 24,081 total'
    fvf = 'home'; str = '56%'; strSource = 'HAND: ZIK 1,891 sold / eBay UK 3,400+ active'; s50 = '30+/30d: sahilsa-329 218, lupo-store 201, estoba_20 200, bestchoice2005 164, lyzoo-group 130'
    s500 = 'lupo-store 24,073, gbmobile 5,142, lyzoo-group 2,441, fs.accessories 1,629, estoba_20 798'; listings = '3,400+ eBay UK Buy It Now results'
    seasonality = 'christmas_plus_evergreen'; target = 'Christmas'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (provisional)'; status = 'QUALIFIED'
    trend = 'Steady, Christmas uplift (turkey)'; searchQ = 'digital meat thermometer'
    notes = 'Profit 1.72, ROI 116%, min listing 3.63, buffer 1.63. Price-war market. Battery inclusion UNKNOWN - include a button cell or state clearly.' }
Rec @{ id = 'AX-20261109-05'; cat = 'SELECTED'; kind = 'ali'; name = 'Smart induction zoom LED headlamp, USB rechargeable, 1 pack (item 1005006863824680)'; srcUrl = 'https://www.aliexpress.com/item/1005006863824680.html'
    cost = 5.31; costNote = 'SKU List 1 PACK 5.31; struck 10.63 not used; +4% FX added; price history not read'; stock = '16 (1 PACK) - RELAXED'; delivery = '14 - 17 Nov (free shipping)'; rating = '4.9 (556 reviews)'
    srcSales = '3,000+ sold (Choice)'; srcSeller = 'Sophie Solar Light Store, feedback % UNKNOWN'; seller = 'foido'; ebayPrice = 9.95
    refNote = 'Near-match reference foido T6 zoom headlamp 9.95 (62/30d, 1,248 total)'
    fvf = 'home'; str = '101% (narrow)'; strSource = 'HAND: narrow "zoom headlamp rechargeable sensor" 84 sold / 83 active; broad "rechargeable head torch led" 995 / 11,000+ = 9%'
    s50 = 'broad search only: openbasket 95, foido 62, carmen-l33 54, GrabDealUK 42 (narrow: foido only)'; s500 = 'foido 1,248, raal 637, carmen 554, openbasket 525'
    seasonality = 'winter'; target = 'NONE'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS - CRITERIA RELAXED (user approved 9 Nov)'; status = 'QUALIFIED'
    trend = 'Steady, winter uplift'; searchQ = 'zoom headlamp rechargeable sensor'
    exception = 'stock 16 < 20; near-match reference; strong sellers only on broad search; margin under 30% (passes on ROI)'
    notes = 'Profit 1.77, ROI 32.1%, margin 17.8%, min listing 9.13, max safe cost 5.84, buffer 1.44. Relaxed on user instruction - not fully compliant.' }

# ---------------- REJECTED: AliExpress ----------------
AE 'AX-20261109-06' 'LED pillar candles 3-pack with remote (homedepo_0 item)' 9.40 '3-19 per variant' 9.99 'festive-lights 9.99 (113/30d); market passes gates' 'stock' 'all Choice variants stock 3-19' 'stock 50+ (seasonal)' 'led pillar candles remote' 'christmas_plus_evergreen' 'Christmas'
AE 'AX-20261109-07' 'Christmas bauble storage box 64 grid' 8.65 'UNKNOWN' 11.50 'homedepo_0 6/30d' 'price' 'landed ~9.00, min listing ~14.85 vs eBay 8.99-11.50' 'eBay reference at or above minimum listing price' 'christmas bauble storage box' 'christmas' 'Christmas'
AE 'AX-20261109-08' 'Christmas pathway stake lights (snowflake / tree)' $null 'UNKNOWN' 16.99 'homedepo_0 items' 'source_demand' 'top Choice item 487 sold' 'Choice + 500+ sold' 'christmas pathway stake lights' 'christmas' 'Christmas'
AE 'AX-20261109-09' 'Christmas tree storage bag' 4.69 'UNKNOWN' 5.95 'ramretailgroup24 5.95 (48/30d, only 30+ seller)' 'price' 'eBay 3.19-5.95 vs landed ~4.9' 'profit of at least GBP 1' 'christmas tree storage bag' 'christmas' 'Christmas'
AE 'AX-20261109-10' 'Light-up Christmas present boxes 3-pack' 20.79 'UNKNOWN' 24.99 'homedepo_0 24.99' 'price' 'AliExpress 20.79 vs eBay 24.99' 'margin 30% or ROI 20%' 'christmas light up present boxes' 'christmas' 'Christmas'
AE 'AX-20261109-11' 'Christmas string lights battery 10m (PVC wire)' $null 'UNKNOWN' 8.49 'homestoreuk 8.49 (92/30d)' 'no_source' 'AliExpress Choice offers only copper-wire micro lights (different product)' 'same product on source' 'christmas string lights battery 10m' 'christmas' 'Christmas'
AE 'AX-20261109-12' '3pc hanging plush gonk gnomes, Red (item 1005007996219197)' 1.96 '656' 3.33 '16a median of 5 lowest 3.20-3.55' 'price' 'median 3.33 < minimum listing ~4.20' 'reference at or above minimum listing price' '3pcs christmas gnome plush hanging ornaments' 'christmas' 'Christmas'
AE 'AX-20261109-13' 'Bike lights front + rear set (T6)' 7.09 'UNKNOWN' 8.99 'junglezon-uk 8.99 (57/30d)' 'price' 'complete set 7.09 vs eBay 8.99; T6 1.76 item is front only' 'profit of at least GBP 1' 'usb rechargeable bike lights set'
AE 'AX-20261109-14' 'Pocketman zoom headlamp 18650 (item 1005002510984334)' 5.89 'UNKNOWN' 9.95 'foido 9.95' 'cost_buffer' 'one-time offer 2.89; regular 5.89 gives buffer profit ~0.91' 'profit at +6% cost of at least GBP 1' 'rechargeable head torch led'
AE 'AX-20261109-15' 'COB motion sensor headlamp (item 1005009121229695)' 4.69 '116' $null 'no eBay market for sensor COB headlamps (~0 sales)' 'demand' 'no matching eBay reference with 5+ sales' 'reference seller with 5+ sales in 30 days' 'headlamp motion sensor rechargeable cob'
AE 'AX-20261109-16' 'Digital luggage scale 50kg' $null 'UNKNOWN' 6.95 'foido 6.95 (51/30d)' 'strong_sellers' 'only 2 sellers with 30+ sales/30d' '3+ sellers with 30+/30d' 'digital luggage scale 50kg'
AE 'AX-20261109-17' 'LED beanie hat rechargeable' $null 'UNKNOWN' $null 'anita796417 62, london-store86 38, pariella 37' 'strong_sellers' 'only 1 seller with 500+ total' '2+ sellers with 500+ total sold' 'led beanie hat rechargeable' 'winter'
AE 'AX-20261109-18' '100W solar panel trickle charger kit' $null 'UNKNOWN' $null 'chengxi9588 138, ccclo_93 72, simonsmart6 65' 'strong_sellers' 'no seller with 500+ total' '2+ sellers with 500+ total sold' '100w solar panel kit'
AE 'AX-20261109-19' 'Electric salt and pepper grinder' $null 'UNKNOWN' $null 'lapolii 46 (manual mill) only' 'strong_sellers' 'only 1 seller with 30+/30d' '3+ sellers with 30+/30d' 'electric salt and pepper grinder'
AE 'AX-20261109-20' 'Digital tyre pressure gauge' $null 'UNKNOWN' $null 'market weak' 'strong_sellers' 'digital gauges 1-2 sales each' '3+ sellers with 30+/30d' 'digital tyre pressure gauge' 'winter'

# ---------------- REJECTED: Go Dropship ----------------
GD 'GD-20261109-21' 'Garden lawn edging 10m (homiely match)' 10.48 'UNKNOWN' 10.99 'homiely 10.99' 'price' 'cost 10.48 vs eBay 10.99' 'profit of at least GBP 1' 'garden edging 10m'
GD 'GD-20261109-22' 'Christmas paper party garland HOM-63516' 7.47 'UNKNOWN' 5.54 'eBay similar 2 sold/30d avg 5.54' 'demand' '2 sold/30d' 'reference seller with 5+ sales' 'christmas party decorations banner' 'christmas' 'Christmas'
GD 'GD-20261109-23' 'Mini USB rechargeable lint remover' 5.44 'UNKNOWN' 8.99 'PrimePickMall 8.99' 'price' 'profit ~0.95, ROI under 20%' 'profit of at least GBP 1' 'electric lint remover'
GD 'GD-20261109-24' '5.3in LED digital alarm clock HOM-17459' 5.58 1036 8.79 'exact-title listings 7.63-8.79 (23)' 'price' 'eBay 7.63-8.79 < minimum listing ~9.42' 'reference at or above minimum listing price' '5.3 inch led digital alarm clock'
GD 'GD-20261109-25' 'Fluffy dog cat bed mat 70x50' 7.62 192 $null 'exact-title listings 0-1 sales each' 'strong_sellers' 'no seller with 30+/30d for this item' '3+ sellers with 30+/30d' 'dog bed mat plush washable'
GD 'GD-20261109-26' '10 sets 2-pin super seal connectors' 4.31 446 7.98 'max 11/30d' 'strong_sellers' 'one seller with 30+/30d' '3+ sellers with 30+/30d' 'super seal connector 2 pin'
GD 'GD-20261109-27' 'Christmas word plate LED decoration kit COM-25430' 3.99 80 5.99 '16a median of 5 lowest 5.99' 'price' 'median 5.99 < minimum ~6.89' 'reference at or above minimum listing price' 'christmas decoration kit' 'christmas' 'Christmas'
GD 'GD-20261109-28' '6pc clip-on feather baubles' 4.92 63 4.27 '6-packs 2.69-4.27' 'price' 'price war below cost' 'profit of at least GBP 1' 'clip on feather glitter baubles' 'christmas' 'Christmas'
GD 'GD-20261109-29' 'Square silicone air fryer pot' 5.76 60 4.37 'exact 3.30-4.37' 'price' 'eBay below cost' 'profit of at least GBP 1' 'square silicone air fryer liner pot'
GD 'GD-20261109-30' 'Adult mealtime bib clothing protector' 5.33 909 $null 'top 11/30d' 'strong_sellers' 'no seller with 30+/30d' '3+ sellers with 30+/30d' 'adult mealtime bib'
GD 'GD-20261109-31' '120cm cable tidy zip sleeve' 4.78 549 $null 'top 11/30d' 'strong_sellers' 'no seller with 30+/30d' '3+ sellers with 30+/30d' 'cable tidy zip sleeve'
GD 'GD-20261109-32' 'Dog grass pad with tray HB-76218' 7.40 6 12.58 'rainbow-andy77 12.58' 'stock' 'UK stock 6' 'stock 20+' 'dog toilet grass pad'
GD 'GD-20261109-33' '3pc golf club headcovers' 8.53 439 12.33 'market 29 sold, max 5/30d' 'demand' 'off-season, no seller 30+' '3+ sellers with 30+/30d' 'golf club head covers 3pcs'
GD 'GD-20261109-34' 'Telescopic DAB/FM aerial with 3 adapters' 4.62 437 7.39 'exact 3.15-7.39' 'strong_sellers' 'no seller with 30+/30d' '3+ sellers with 30+/30d' 'telescopic dab fm aerial'
GD 'GD-20261109-35' 'Large cat litter box with drawer' 17.67 125 $null 'market 9 sold/30d' 'demand' '9 sold/30d market-wide' '3+ sellers with 30+/30d' 'cat litter box drawer anti splash'
GD 'GD-20261109-36' '4x gazebo sand bag weights' 5.98 416 8.53 'eBay 8.53 (58/30d)' 'price' 'profit ~0' 'profit of at least GBP 1' 'gazebo weights sand bags'
GD 'GD-20261109-37' 'Clear plastic dish drainer with drip tray' 7.20 'UNKNOWN' 12.89 'usave-shop 12.89 (37/30d, only 30+ seller)' 'strong_sellers' 'only 1 seller with 30+/30d' '3+ sellers with 30+/30d' 'dish drainer rack drip tray'
GD 'GD-20261109-38' 'Battery milk frother stirrer' 4.73 'UNKNOWN' 4.00 'battery frothers ~2-4' 'price' 'eBay below cost' 'profit of at least GBP 1' 'milk frother'
GD 'GD-20261109-39' '12V 3.1A dual USB socket panel' 4.44 267 6.89 'exact 3.58-6.89, ~0-1 sales' 'demand' 'no seller with 5+ sales' 'reference seller with 5+ sales' '12v dual usb socket panel'
GD 'GD-20261109-40' '5pcs inline blade fuse holder' 3.91 885 7.98 'only 3waycomp 31/30d' 'strong_sellers' 'only 1 seller with 30+/30d' '3+ sellers with 30+/30d' 'inline blade fuse holder'
GD 'GD-20261109-41' 'Reusable castor oil pack kit' 6.54 431 $null 'kits 0-2/30d' 'demand' 'no seller with 5+ sales' 'reference seller with 5+ sales' 'castor oil pack wrap'
GD 'GD-20261109-42' 'Heatless curler rods 5pcs' 5.83 120 $null '4 sold market-wide' 'demand' '4 sold/30d' 'reference seller with 5+ sales' 'heatless curler rods'
GD 'GD-20261109-43' 'Electric makeup brush cleaner' 8.84 97 $null 'no matching market' 'demand' 'no matching eBay listings with sales' 'reference seller with 5+ sales' 'electric makeup brush cleaner'
GD 'GD-20261109-44' '180 degree flip barn door latch' 3.06 115 $null '3 sold market-wide' 'demand' '3 sold/30d' 'reference seller with 5+ sales' '180 degree flip barn door latch'
GD 'GD-20261109-45' 'Magnetic thermal door curtain 80-90cm' 10.92 188 $null 'thermal curtains ~0 sales' 'demand' 'no seller with 5+ sales' 'reference seller with 5+ sales' 'magnetic thermal door curtain' 'winter'
GD 'GD-20261109-46' 'Car air vent holder + windscreen suction mount' 4.86 594 7.49 'junglezon-uk 7.49 (61/30d)' 'price' 'profit ~0.56' 'profit of at least GBP 1' 'car phone holder windscreen suction'
