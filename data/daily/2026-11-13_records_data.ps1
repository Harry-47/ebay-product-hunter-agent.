# Products evaluated 11-13 Nov 2026 (from data/notes/2026-11-13_hunt_notes.txt and 2026-11-11 notes). Dot-sourced by tools/build_manual_workbook.ps1.
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

# ---------------- SELECTED: Go Dropship ----------------
Rec @{ id = 'GD-20261111-05'; cat = 'SELECTED'; kind = 'gd'; name = 'Frost protection fleece plant jacket 80x100cm 30gsm HOM-55114'; srcUrl = 'https://www.godropship.co.uk/'
    cost = 3.13; costNote = 'Go Dropship 3.13 (+5% buying fee)'; stock = '1295 (UK)'; delivery = 'Royal Mail Large Letter'; srcSales = 'Home & Garden Bestselling p1'
    seller = 'euro-imports'; ebayPrice = 7.75; refNote = 'euro-imports item 302519799204 Medium 105x80 1-pack 7.75 (114/30d); nearest size match'
    fvf = 'gar'; str = '293%'; strSource = 'HAND: ~1,300 sold / 444 active'; s50 = 'strong sellers met'; seasonality = 'winter'; compliance = 'COMPLIANCE_REVIEW'
    decisionNote = 'PASS'; status = 'QUALIFIED'; trend = 'Winter seasonal'; searchQ = 'frost protection fleece plant jacket'
    notes = 'Profit 2.41, margin 31.2%, ROI 73.4%. Large Letter (no tracking) - not-received risk flag.' }
Rec @{ id = 'GD-20261113-11'; cat = 'SELECTED'; kind = 'gd'; name = '2 in 1 Pet Feeder Food and Water Dispenser PET-73110'; srcUrl = 'https://www.godropship.co.uk/'
    cost = 8.64; costNote = 'Go Dropship 8.64 (+5% buying fee); price stable since 2024-11-14'; stock = '320 (UK)'; delivery = 'Tracked 2 Business Days'; weight = '978 g'
    seller = 'thinkprice'; ebayPrice = 19.99; refNote = 'thinkprice same feeder 19.99 (14/30d, was 29.99); coupon check at 15.99 still passes (profit 2.58)'
    fvf = 'home'; str = '20.4%'; strSource = 'HAND: 109 sold / 535 active'; s50 = 'small-seller route: selectifyltd 17, trustedhomedirect 9, persimmon4 8, lumah-77 7'
    seasonality = 'evergreen'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (small-seller demand route)'; status = 'QUALIFIED'; searchQ = '2 in 1 pet feeder water dispenser'
    exception = 'demand via small-seller route (user rule 13 Nov)'; notes = 'Profit 5.70, margin 28.5%, ROI 62.9%, min listing 15.02, max safe cost 11.72.' }
Rec @{ id = 'GD-20261113-14'; cat = 'SELECTED'; kind = 'gd'; name = '5 pcs Collapsible Drainage Waste Water Pipes Grey'; srcUrl = 'https://www.godropship.co.uk/'
    cost = 4.93; costNote = 'Go Dropship 4.93 (+5% buying fee); price stable since 2025-02-07'; stock = '1335 (UK)'; delivery = 'Tracked'; weight = '198 g'
    seller = 'la220594'; ebayPrice = 8.99; refNote = 'la220594 8.99 (7/30d)'
    fvf = 'home'; str = '381%'; strSource = 'HAND: 179 sold / 47 active'; s50 = 'small-seller route: e_hub92 22, aisal_7194 8, la220594 7'
    seasonality = 'evergreen'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (small-seller demand route)'; status = 'QUALIFIED'; searchQ = 'caravan collapsible waste water pipe'
    exception = 'demand via small-seller route'; notes = 'Profit 1.49, ROI 28.7%, min listing 8.45, max safe cost 5.28.' }
Rec @{ id = 'GD-20261113-15'; cat = 'SELECTED'; kind = 'gd'; name = 'Black Car Headrest Pillow Neck Support Cushion 1pc'; srcUrl = 'https://www.godropship.co.uk/black-car-headrest-pillow-neck-support-cushion-ergonomic-driving-comfort-pad'
    cost = 4.72; costNote = 'Go Dropship 4.72 (+5% buying fee); price updated 2026-07-14 (PRICE_RECENTLY_CHANGED)'; stock = '290 (UK)'; delivery = 'Tracked 2 Business Days'; weight = '137 g'
    seller = 'autobits_uk'; ebayPrice = 10.92; refNote = 'autobits_uk single black pillow 10.92 (88/30d)'
    fvf = 'home'; str = '34%'; strSource = 'HAND: 325 sold / 964 active'; s50 = 'small-seller route: mehrozeltd 21, rogueassassi 15, onlinebuysky 9, dealzmaster365 7, selectifyltd 6'
    seasonality = 'evergreen'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (small-seller demand route)'; status = 'QUALIFIED'; searchQ = 'car seat headrest pillow neck cushion'
    exception = 'demand via small-seller route; PRICE_RECENTLY_CHANGED'; notes = 'Profit 3.17, ROI 64.0%, min listing 7.90, max safe cost 6.45.' }
Rec @{ id = 'GD-20261113-16'; cat = 'SELECTED'; kind = 'gd'; name = 'Cat Scratch Mat 30x100cm Self Adhesive Gray'; srcUrl = 'https://www.godropship.co.uk/'
    cost = 4.69; costNote = 'Go Dropship 4.69 (+5% buying fee); price updated 2026-07-07 (PRICE_RECENTLY_CHANGED)'; stock = '309 (UK)'; delivery = 'Tracked 2 Business Days'; weight = '119 g'
    seller = 'am_864296 (Trovia CO)'; ebayPrice = 9.90; refNote = 'am_864296 item 188858329600 30x100 Light Grey 9.90 (26 in 1M)'
    fvf = 'home'; str = '40%'; strSource = 'HAND: 170 sold / 421 active'; s50 = 'small-seller route: naveed_eshop 33, am_864296 24, brighthavenstore 16, primedeals804 15'
    seasonality = 'evergreen'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (small-seller demand route)'; status = 'QUALIFIED'; searchQ = 'cat scratch mat self adhesive'
    exception = 'demand via small-seller route; PRICE_RECENTLY_CHANGED'; notes = 'Profit 2.09, ROI 42.5%, min listing 8.51, max safe cost 5.57.' }

# ---------------- SELECTED: AliExpress ----------------
Rec @{ id = 'AX-20261113-17'; cat = 'SELECTED'; kind = 'ali'; name = 'DIY Embroidery Stitch Book Kit for Beginners, variant 2391A1 (item 1005010332244987)'; srcUrl = 'https://www.aliexpress.com/item/1005010332244987.html'
    cost = 3.74; costNote = 'SKU List 3.74, chart flat (fake sale); +4% FX'; stock = '440'; delivery = '19 - 23 Nov (Choice, free shipping)'; rating = '4.9 (126 reviews)'; srcSales = '2,000+ sold (Choice)'
    seller = 'moni-3019'; ebayPrice = 7.99; refNote = 'moni-3019 Embroidery Stitch Book Kit 7.99 (43/30d)'
    fvf = 'cl'; str = '87%'; strSource = 'HAND: ZIK 288 sold / 329 active'; s50 = 'small-seller route: moni-3019 43, akintere-87 26, jowat_4967 19, tedmon-0 15'
    seasonality = 'christmas_plus_evergreen'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (small-seller demand route)'; status = 'QUALIFIED'; searchQ = 'embroidery stitch book kit'
    exception = 'demand via small-seller route; nearest possible match'; notes = 'Profit 1.82, ROI 46.8%, buffer 1.59, max safe cost 4.53. Found via competitor research.' }
Rec @{ id = 'AX-20261113-18'; cat = 'SELECTED'; kind = 'ali'; name = '45 degree hose clip pliers, swivel jaw, Color A (item 1005008955232147)'; srcUrl = 'https://www.aliexpress.com/item/1005008955232147.html'
    cost = 3.31; costNote = 'SKU List Color A 3.31; chart 0.97 Aug -> 3.60 Oct (risk row at 3.60 still passes, profit 1.49); +4% FX'; stock = '49'; delivery = '18 - 21 Nov (Choice)'; rating = '4.6 (320 reviews)'; srcSales = '2,000+ sold (Choice)'
    srcSeller = 'Newshark Store, 96% positive'; seller = 'dgoautopartsteam'; ebayPrice = 6.99; refNote = 'dgoautopartsteam 45 deg hose clip pliers 6.99 (63/30d, 3,290 fb)'
    fvf = 'home'; str = '62%'; strSource = 'HAND: ZIK 277 sold / 445 active'; s50 = '30+/30d: skybluee05 69, dgoautopartsteam 63, storemanagers 49'; s500 = 'skybluee05 2,980, hippoproduct 1,019'
    seasonality = 'evergreen'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS'; status = 'QUALIFIED'; searchQ = 'hose clip pliers swivel jaw'
    notes = 'Profit 1.79, ROI 52.1%, min listing 6.03, max safe cost 4.07, buffer 1.58. Found via akintere-87 competitor research.' }
Rec @{ id = 'AX-20261113-19'; cat = 'SELECTED'; kind = 'ali'; name = 'Self-heating pet pad Gray 40x50cm (item 1005010155238697)'; srcUrl = 'https://www.aliexpress.com/item/1005010155238697.html'
    cost = 3.20; costNote = 'SKU List 40x50 3.20 (chart 1.64 -> 3.20, current is the high); +4% FX'; stock = '394'; delivery = '18 - 21 Nov (Choice)'; rating = '4.9 (841 reviews)'; srcSales = '10,000+ sold (Choice)'
    seller = 'ronch_5215'; ebayPrice = 7.29; refNote = 'ronch_5215 item 127628868447 7.29 (30/30d), size not stated'
    fvf = 'home'; str = '45%'; strSource = 'HAND: ZIK 629 sold / 1,400+ active'; s50 = 'small-seller route: ma_266584 62, swiftonlineshop 48, uk_salehouse 43, brittonvault 42'
    seasonality = 'winter'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (small-seller demand route)'; status = 'QUALIFIED'; searchQ = 'self heating pet mat'
    exception = 'demand via small-seller route; size not found, nearest match'; notes = 'Profit 1.82, ROI 54.6%, min listing 6.28, max safe cost 3.98. 50x70 (4.71) fails - sell 40x50 only. Price-war market.' }
Rec @{ id = 'AX-20261113-20'; cat = 'SELECTED'; kind = 'ali'; name = 'Digital pocket scale 500g x 0.01g (item 1005010285414833)'; srcUrl = 'https://www.aliexpress.com/item/1005010285414833.html'
    cost = 3.55; costNote = 'SKU List 3.55, chart flat (fake sale); +4% FX'; stock = '114'; delivery = '18 - 21 Nov (Choice)'; rating = '4.9 (2,775 reviews)'; srcSales = '10,000+ sold (Choice)'
    seller = 'lupo-store'; ebayPrice = 7.99; refNote = 'lupo-store Digital Scales 0.01g 200g 7.99 (133/30d)'
    fvf = 'cl'; str = '83%'; strSource = 'HAND: ZIK 498 sold / 599 active'; s50 = '30+/30d: shihe01 146, lupo-store 133, faisoh.nexus 52, shackaway_online 39'; s500 = 'lupo-store 20,120, gbmobile 2,096, golden_beads 1,478'
    seasonality = 'evergreen'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS'; status = 'QUALIFIED'; searchQ = 'digital pocket scale 0.01g 200g'
    exception = 'nearest match (500g vs 200g)'; notes = 'Profit 1.83 at Jewellery 14.9% fee, ROI 49.6%, min listing 6.93, max safe cost 4.34. Price war (3.99-5.98). Button battery.' }
Rec @{ id = 'AX-20261113-21'; cat = 'SELECTED'; kind = 'ali'; name = 'Universal pushchair / pram rain cover C174 PVC (item 1005008675941671)'; srcUrl = 'https://www.aliexpress.com/item/1005008675941671.html'
    cost = 4.12; costNote = 'SKU List 4.12 (chart 4.00 -> 4.12); SuperDeals max 10/shopper; +4% FX'; stock = '20'; delivery = '18 - 21 Nov (Choice)'; rating = '4.6 (62 reviews)'; srcSales = '900+ sold (Choice)'
    srcSeller = 'RUZOFO Official Store, 95%'; seller = 'lupo-store'; ebayPrice = 7.99; refNote = 'lupo-store Universal Pushchair Rain Cover 7.99 (34/30d)'
    fvf = 'home'; str = '43%'; strSource = 'HAND: ZIK 405 sold / 950 active'; s50 = '30+/30d: buystarget 56, for-your-little 37, lupo-store 34'; s500 = 'buystarget 3,935, uksupply24x7 1,787, Cakepackaginguk 558'
    seasonality = 'evergreen'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (low confidence)'; status = 'QUALIFIED'; searchQ = 'universal pushchair rain cover'
    exception = 'no exact match (pram-shaped cover); stock exactly 20'; notes = 'Profit 1.62, ROI 37.9%, min listing 7.24, max safe cost 4.72.' }

# ---------------- REJECTED: AliExpress ----------------
AE 'AE-20261111-11' 'USB LED curtain lights (item 1005006125200079)' 3.82 '153' 7.19 'purelygenuineuk 7.19' 'duplicate' 'previous pass 24 Oct (curtain lights)' 'no repeat passes' 'usb led curtain lights'
AE 'AE-20261113-12' 'Christmas cushion covers 4-pack' 10.44 'UNKNOWN' 9.91 '4-pack 6.28-9.91' 'price' 'every 4-pack costs more than eBay 4-pack price' 'profit of at least GBP 1' 'christmas cushion covers 4 pack' 'christmas' 'Christmas'
AE 'AE-20261113-13' 'Women fluffy coral fleece bed socks' 1.10 'UNKNOWN' 2.56 '5 pairs 5.85 (104), single 2.56' 'price' 'single pair profit ~0.56' 'profit of at least GBP 1' 'fluffy bed socks' 'winter'
AE 'AX-20261111-01' 'Seal strip 35mm x 5m (item 1005006995198589)' 3.55 '995' 5.99 'manchester.beds 5.99' 'price' 'profit ~0.72' 'profit of at least GBP 1' 'self adhesive seal strip'
AE 'AE-20261113-14' '137pcs Christmas snowflake window clings (item 1005010289273339)' 2.32 '230' 3.98 'royalmart-ltd 3.98' 'price' 'profit 0.36; min listing 4.77' 'reference at or above minimum listing price' 'christmas window stickers' 'christmas' 'Christmas'
AE 'AX-20261113-15' 'Bike light set (item 1005005200740874 / 1005005200736894)' 2.46 'UNKNOWN' 5.99 'ecomm_world 5.99' 'cost' 'sale price max 1 per shopper, regular ~4 > max safe cost 3.12' 'repeatable baseline cost' 'usb rechargeable bike light set'
AE 'AX-20261113-16' 'Lint remover LED display grey (item 1005007097015654)' 3.69 '291' 8.99 'carmen-l33 8.99' 'duplicate' 'previous pass 9 Nov' 'no repeat passes' 'lint remover rechargeable'
AE 'AE-20261113-22' 'Christmas snowflake projector light' 5.02 '42' $null 'muhammadumer-1 8.99' 'sell_through' 'sell-through 142/934 = 15%' 'sell-through 20% (small-seller route)' 'christmas projector light' 'christmas' 'Christmas'
AE 'AE-20261113-23' 'Kids sonic electric toothbrush (item 1005006392879326)' 3.99 '4-8' 11.99 'ye46063 11.99 (36/30d)' 'stock' 'stock 4 and 8' 'stock 20+' 'kids electric toothbrush'
AE 'AE-20261113-24' 'Long reach hose clamp pliers (items 1005009508923644, 1005008660255509)' 4.00 '0-20' 14.02 'akintere-87 14.02' 'source_demand' 'not Choice / stock under 20' 'Choice + stock 20+' 'long reach hose clamp pliers'
AE 'AE-20261113-25' '4pcs trim clip removal pliers set' 8.40 'UNKNOWN' 7.99 'dgoautopartsteam 7.99 (41/30d)' 'price' 'AliExpress 8.40 > eBay 7.99' 'profit of at least GBP 1' 'trim clip removal pliers set'
AE 'AE-20261113-26' 'Memory foam travel neck pillow' 5.90 'UNKNOWN' 9.99 'homedepo_0 set 9.99 (48/30d)' 'price' 'too thin vs 9.99 set with mask/plugs' 'margin 30% or ROI 20%' 'travel neck pillow memory foam'
AE 'AE-20261113-27' 'Bath pillow suction cups' 8.40 'UNKNOWN' 12.99 'homedepo_0 branded Your Bathroom 12.99' 'price' 'profit under 1; mesh 4.00 vs 5.79' 'profit of at least GBP 1' 'bath pillow suction cups'
AE 'AE-20261113-28' '3in1 staple gun (item 1005013010762429)' 3.76 'UNKNOWN' 9.99 'homedepo_0 9.99 (82/30d)' 'source_demand' 'one-time offer price; Local+ not Choice' 'Choice + repeatable price' 'staple gun heavy duty'
AE 'AE-20261113-29' 'Cat toys 14pc set (item 1005009738004906)' 2.63 '22' 3.42 '21pc sets 2-3' 'price' 'eBay price war 2-3' 'profit of at least GBP 1' 'cat toys set kitten'
AE 'AE-20261113-30' 'Circuit breaker 20-300A (item 1005007472209824)' 7.97 'UNKNOWN' 9.49 'bestbuy-lw2020 9.49' 'cost' '1.99 is max-1/shopper; struck 7.97 fails' 'repeatable baseline cost' 'circuit breaker reset 12v 24v'
AE 'AE-20261113-31' 'Solar camping lantern power bank (item 1005007344511475)' 5.91 '135' 8.87 'scunltdstore 8.87' 'price' 'profit ~0.25' 'profit of at least GBP 1' 'solar camping lantern power bank'
AE 'AE-20261113-32' 'Nose hair trimmer (3 AliExpress items)' 3.30 '0-14' 3.63 'iqah01 capsule 3.63 (103/30d)' 'stock' 'stock under 20 or eBay price too low' 'stock 20+ / profit GBP 1' 'nose hair trimmer battery'
AE 'AE-20261113-33' 'Digital vernier caliper 150mm stainless' 13.40 'UNKNOWN' 17.21 'mylittlestuff 17.21' 'price' 'AliExpress 13.40 vs 17.21 - loss' 'profit of at least GBP 1' 'digital vernier caliper 150mm'

# ---------------- REJECTED: Go Dropship ----------------
GD 'GD3-01' '2.5ft long hot water bottle with fleece cover' 10.50 50 7.85 'infinitedeals776 7.85' 'price' 'cost above eBay price; BS 1970 risk' 'profit of at least GBP 1' 'long hot water bottle' 'winter'
GD 'GD3-02' 'Large Christmas Santa sack 60x50' 4.36 97 4.45 'qdsupplies 4.45 (80/30d)' 'price' 'cost ~eBay price' 'profit of at least GBP 1' 'christmas santa sack' 'christmas' 'Christmas'
GD 'GD3-03' '3pcs 28cm door wreath hanger black' 5.12 499 7.99 'elara-london 7.99 (0 sold)' 'price' 'profit ~0.93' 'profit of at least GBP 1' 'door wreath hanger' 'christmas' 'Christmas'
GD 'GD3-04' '20x shatterproof Christmas baubles 6cm' 8.13 94 $null 'top seller 20/30d' 'strong_sellers' 'no seller 30+' '3+ sellers with 30+/30d' 'shatterproof christmas baubles' 'christmas' 'Christmas'
GD 'GD3-05' 'Christmas table runner snowflake' 4.20 166 $null 'top sellers single digits' 'demand' '199 sold across 100 listings' 'reference seller with 5+ sales' 'christmas table runner' 'christmas' 'Christmas'
GD 'GD3-06' 'Magnetic thermal door curtain 90x210' 11.99 188 18.81 'fairmontcommerceltd 18.81' 'price' 'ROI 12.6%; STR 30%' 'ROI 20% / sell-through 40%' 'magnetic thermal door curtain' 'winter'
GD 'GD3-07' '15x mini robin Christmas decorations' 5.13 84 $null 'robin listings 1-5 sold' 'demand' 'no seller with 5+ sales' 'reference seller with 5+ sales' 'christmas robin decorations' 'christmas' 'Christmas'
GD 'GD3-08' 'Detachable seat back hanging organiser' 7.90 550 12.20 'digiworldstore 12.20 (1 sold)' 'strong_sellers' 'top organiser 24/30d' '3+ sellers with 30+/30d' 'car seat back organiser'
GD 'GD3-10' '10 pairs white hotel disposable slippers' 6.11 902 10.99 'wakerup 10.99 (30/30d)' 'strong_sellers' 'only 2 sellers with 30+' '3+ sellers with 30+/30d' 'disposable slippers hotel'
GD 'GD-20261113-13' '10 pcs double coat hooks black HOM-65780' 4.97 209 8.49 'Banstoreltd 8.49 (26 in 1M)' 'price' 'ROI 19.8% (by 2p)' 'ROI 20%' 'double coat hooks heavy duty'
GD 'GD2-09' '24 pockets over door shoe organiser' 7.06 'UNKNOWN' 11.58 'creeper-43 11.58' 'price' 'ROI ~15.6%' 'ROI 20%' '24 pocket over door shoe organiser'
GD 'GD-28' 'Natural suede leather car cleaning cloth' 4.45 'UNKNOWN' 6.53 'listings 3.69-6.53, max 4 sold' 'demand' 'no small-seller route' 'reference seller with 5+ sales' 'suede car cleaning cloth'
