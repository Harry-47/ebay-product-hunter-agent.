# Products evaluated on 2026-11-06 (from data/notes/2026-11-06_hunt_notes.txt). Dot-sourced by tools/build_manual_workbook.ps1.
# Keys omitted = UNKNOWN in the workbook. ASCII only. Sell-through is hand calculated: ZIK sold 30d / eBay UK active (BIN, New, UK).
function Merge-H($a, $b) { foreach ($k in $b.Keys) { $a[$k] = $b[$k] }; return $a }
function GD($id, $name, $cost, $stock, $ebay, $ref, $rule, $seen, $limit, $q, $seas = 'evergreen', $tgt = 'NONE', $extra = @{}) {
    Rec (Merge-H @{ id = $id; cat = 'REJECTED'; kind = 'gd'; name = $name; cost = $cost; costNote = "Go Dropship price $cost (+5% buying fee added by the calculation)"; stock = "$stock (UK)"; ebayPrice = $ebay; refNote = $ref
            seasonality = $seas; target = $tgt; compliance = 'COMPLIANCE_REVIEW'; failedRule = $rule; seen = $seen; limit = $limit; reason = $seen; searchQ = $q; mayChange = 'yes'; status = 'WATCH' } $extra)
}

# ---------------- SELECTED ----------------
Rec @{ id = 'AX-20261106-01'; cat = 'SELECTED'; kind = 'ali'; name = 'LED flameless tea lights 12-pack, warm light (item 1005006783187167)'; srcUrl = 'https://www.aliexpress.com/item/1005006783187167.html'
    cost = 3.13; costNote = 'SKU warm light 12pcs 3.13 (6pcs 2.03); +4% FX added'; stock = '231 (12pcs warm)'; delivery = '12 - 15 Nov (Choice, free shipping)'; rating = '4.3'
    srcSales = '10,000+ sold (Choice)'; srcSeller = 'Willam Jiang-3 store, 90.7% positive'; seller = 'homedepo_0'; ebayPrice = 8.99
    refNote = 'Reference homedepo_0 12-pack 8.99 (31 sales/30d; also 10.99 with 60/30d); cheaper mixed packs 1.79-5.50 elsewhere'
    fvf = 'home'; str = '62%'; strSource = 'HAND: ZIK 809 sold / eBay UK 1,300+ active (at most)'; s50 = '30+/30d: khush_787 175, dukkano 72, harrypotterhub 67, homedepo_0 60, mikebaclayon 43 (8 sellers)'
    s500 = 'dfahome 666, lancashire-outlet 649, ominibay 556'; listings = '1,300+ eBay UK Buy It Now results'
    variations = '2 pack sizes (6 / 12)'; seasonality = 'christmas_plus_evergreen'; target = 'Christmas'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (provisional, hand calculation)'; status = 'QUALIFIED'
    trend = 'Steady demand, rising into Christmas'; searchQ = '12 led flameless tea lights'
    notes = 'Flags: price war; battery product (UKCA/CE); AliExpress rating exactly at the 4.3 limit. Hand profit about 3.39 at 8.99, buffer profit about 3.20.' }
Rec @{ id = 'AX-20261106-02'; cat = 'SELECTED'; kind = 'ali'; name = 'High pressure 5-mode shower head with hose, one-key stop (item 1005007096808809)'; srcUrl = 'https://www.aliexpress.com/item/1005007096808809.html'
    cost = 3.15; costNote = 'SKU Silver 3.15 (Black 2.94 out of stock); 11.11 sale shown, struck price 6.30 (ends 18 Nov); SKU price used per 24 Oct rule; +4% FX added'; stock = '84 (Silver)'; delivery = '12 - 15 Nov (free shipping)'; rating = '4.9 (4,236 reviews)'
    srcSales = '20,000+ sold (Choice on search card)'; srcSeller = 'SmoothTrade Store, feedback % UNKNOWN (not read)'; seller = 'fastsamshop'; ebayPrice = 8.79
    refNote = 'Reference fastsamshop 5-mode handheld set 8.79 (87/30d, 126 total); panuk31 7.99 (90/30d, 3-mode)'
    fvf = 'home'; str = '66%'; strSource = 'HAND: ZIK 1,652 sold / eBay UK 2,500+ active (at most)'; s50 = '30+/30d: kyrie0201 263, marvelsglobal 233, sa897798 114, abby-8888 111, panuk31 90, fastsamshop 87 (10+)'
    s500 = 'zl-plumbuk 6400, chen116a 1943, print_direct247 1927, emporium 1843, panuk31 1051, abby 860'; listings = '2,500+ eBay UK Buy It Now results'
    variations = '2 colours (Silver, Black)'; seasonality = 'evergreen'; target = 'NONE'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS (provisional, store feedback UNKNOWN)'; status = 'QUALIFIED'
    trend = 'Steady evergreen demand'; searchQ = 'high pressure shower head water saving'
    notes = 'Check store feedback is 90%+ before listing. If the price returns to 6.30 after 18 Nov the product loses about 0.06 per sale at 8.79. Price war (cheap heads 2.40-5). Hand profit about 3.21, buffer profit about 3.02.' }
Rec @{ id = 'GD-20261106-03'; cat = 'SELECTED'; kind = 'gd'; name = 'Mens X shape braces 50mm heavy duty (APP-57959)'; srcUrl = 'https://www.godropship.co.uk/search.html?search_categories=all&filter[global][]=APP-57959'
    cost = 5.93; costNote = 'Go Dropship price 5.93 (+5% buying fee added by the calculation); price updated 2 Apr 2025 (stable 19 months)'; stock = '357 (UK)'; delivery = 'Tracked 2 Business Days'; rating = 'not shown'; weight = '259 g'
    srcSales = 'Clothing Accessories Bestselling page 1 (6 Nov)'; srcSeller = 'Go Dropship UK warehouse'; seller = 'angelcity-1'; ebayPrice = 12.99
    refNote = 'Reference angelcity-1 (7,265 feedback) 50mm X shape 12.99, 29 sales/30d, 90 total; volume leaders ukmotorbikes 9.47 and mlaghari 9.99 are below the minimum listing price'
    fvf = 'cl'; str = '247%'; strSource = 'HAND: ZIK 589 sold / eBay UK 238 active'; s50 = '30+/30d: ukmotorbikes 126 (+74), mlaghari 114, trimmingshop 52'
    s500 = 'mlaghari 5851, ukmotorbikes 2939, trimmingshop 2938, zhangq_81 779'; listings = '238 eBay UK Buy It Now results'
    variations = '2 options, adjustable (no sizes)'; seasonality = 'evergreen'; target = 'NONE'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'PASS on ROI (margin under 30%)'; status = 'QUALIFIED'
    trend = 'Steady evergreen demand'; searchQ = 'x shape braces 50mm heavy duty'; exception = 'margin under 30% (passes on 20%+ ROI rule, CLAUDE.md s3)'
    notes = 'Price risk: only one higher-priced mover; at 9.99 profit is about 0.97. Crowded title. ZIK listing type not confirmed on the URL route. Hand profit about 3.23, margin 24.9%, ROI 51.8%.' }

# ---------------- WATCH ----------------
Rec @{ id = 'AX-20261106-04'; cat = 'WATCH'; kind = 'ali'; name = 'Wireless plug-in doorbell 300M, 60 songs (item 1005007476912309)'; srcUrl = 'https://www.aliexpress.com/item/1005007476912309.html'
    cost = 4.29; costNote = 'Shown 4.29 for EU plug black (struck 8.76); UK plug SKU price NOT read'; stock = 'EU plug black 130; UK plug UNKNOWN'; delivery = '12 - 15 Nov (free shipping)'; rating = '4.9 (5,245 reviews)'
    srcSales = 'Choice badge not read'; srcSeller = 'EZHEN Store, 10,000+ sales; feedback % UNKNOWN'; seller = 'jaf4625'; ebayPrice = 11.49
    refNote = 'Refs jaf4625 11.49 (68/30d), genuinehubuk 12.99 (48/30d), claoner-shopuk 14.99 (78/30d)'
    fvf = 'home'; str = '54%'; strSource = 'HAND: ZIK 1,359 sold / eBay UK 2,500+ active (at most)'; s50 = '30+/30d: muhaabr_24 96, superspeed3_77 96, autoworld2018 90, claoner-shopuk 78, jaf4625 68 (11)'
    s500 = 'claoner-shopuk 6431, easylife1983 5334, autoworld2018 2189, farmi94 551'; seasonality = 'evergreen'; target = 'NONE'; compliance = 'COMPLIANCE_REVIEW'
    decisionNote = 'WATCH - UK plug SKU, store feedback and Choice not read'; failedRule = 'cost_basis'; seen = 'UK plug SKU price/stock, store feedback % and Choice badge not read (browser window could not click)'
    limit = 'SKU price and stock of the exact variant; Choice; store 90%+'; reason = 'Data not read; eBay side passes'; mayChange = 'yes'; status = 'WATCH'; recheck = 'next hunt'; searchQ = 'wireless doorbell plug in'
    notes = 'If the UK plug is 4.29: profit about 3.81 at 11.49, margin about 33%. Mains plug: UKCA/CE compliance risk.' }
Rec @{ id = 'GD-20261106-05'; cat = 'WATCH'; kind = 'gd'; name = '200 LED string lights (Go Dropship)'; cost = 6.51; costNote = 'Go Dropship price 6.51 (+5% buying fee)'; stock = '99 (UK)'
    srcSales = 'Lights Bestselling'; ebayPrice = $null; refNote = 'ZIK 1,818 sold, avg 7.91; eBay listings show only "from" prices 3-9'
    seasonality = 'christmas_plus_evergreen'; target = 'Christmas'; compliance = 'COMPLIANCE_REVIEW'; decisionNote = 'WATCH - variant price not readable'; failedRule = 'cost_basis'
    seen = 'eBay 20m variant price not readable without clicks; needs about 11.41+'; limit = 'reference price at or above the minimum listing price'; reason = 'Variant prices not readable'; mayChange = 'yes'; status = 'WATCH'; searchQ = '200 led string lights' }

# ---------------- REJECTED ----------------
GD 'GD-20261106-06' 'Christmas door wreath hanger 28cm' 3.38 1220 4.33 'ZIK 507 sold, average 4.33' 'price' 'eBay average 4.33 cannot reach the minimum listing price' 'profit of at least GBP 1' 'christmas wreath door hanger' 'christmas' 'Christmas'
GD 'GD-20261106-07' 'Window bird feeder, acrylic' 5.38 35 6.04 'ZIK 228 sold, eBay 3.40-6.40' 'price' 'eBay 3.40-6.40 against cost 5.38' 'profit of at least GBP 1' 'window bird feeder acrylic'
GD 'GD-20261106-08' 'Cutlery drawer tray' 4.95 94 9.30 'ZIK 508 sold, average 9.30' 'strong_sellers' 'only 1 seller with 500+ total sold (addisfactory 2,544, branded Addis)' '2+ sellers with 500+ total sold' 'cutlery drawer tray organiser'
GD 'GD-20261106-09' 'Space saving hangers 10-pack' 5.13 'UNKNOWN' 6.31 'ZIK 1,393 sold, average 6.31' 'price' 'eBay average 6.31 against cost 5.13' 'profit of at least GBP 1' 'space saving hangers'
GD 'GD-20261106-10' 'Tool box organiser' $null 'UNKNOWN' $null 'ZIK 107 sold' 'demand' '107 sold in 30 days' '3+ sellers with 30+/30d' 'tool box organiser'
GD 'GD-20261106-11' 'Magnetic thermal door curtain' 10.92 190 18.12 'ZIK 202 sold, average 18.12; neflaca 84/30d' 'strong_sellers' 'only 1 seller with 30+ sales in 30 days (neflaca 84)' '3+ sellers with 30+/30d' 'magnetic thermal door curtain' 'winter' 'UK Winter Season'
GD 'GD-20261106-12' 'Copper crush washers set' $null 'UNKNOWN' 6.50 'ZIK 133 sold, average 6.50' 'demand' '133 sold in 30 days' '3+ sellers with 30+/30d' 'copper crush washers set'
GD 'GD-20261106-13' 'Stainless steel kebab skewers' $null 'UNKNOWN' $null 'ZIK 47 sold' 'demand' '47 sold in 30 days' '3+ sellers with 30+/30d' 'stainless steel kebab skewers'
GD 'GD-20261106-14' 'E-clip circlip kit' $null 'UNKNOWN' 4.59 'ZIK 217 sold, average 4.59' 'price' 'average 4.59, too low for the cost' 'profit of at least GBP 1' 'e clip circlip assortment'
GD 'GD-20261106-15' 'Extra wide jaw adjustable wrench 6 inch' 5.16 'UNKNOWN' 7.58 '6-inch selling price 7.58' 'profit' 'profit about 0.75 at 7.58' 'profit of at least GBP 1' 'wide jaw adjustable wrench'
GD 'GD-20261106-16' 'LCD writing tablet' $null 'UNKNOWN' 6.66 'ZIK 347 sold, average 6.66' 'price' 'average 6.66, too low' 'profit of at least GBP 1' 'lcd writing tablet'
GD 'GD-20261106-17' 'Christmas table runner' $null 'UNKNOWN' $null 'ZIK 188 sold' 'demand' '188 sold in 30 days, weak' '3+ sellers with 30+/30d' 'christmas table runner' 'christmas' 'Christmas'
GD 'GD-20261106-18' 'Tabard apron' $null 'UNKNOWN' $null 'ZIK 113 sold' 'demand' '113 sold in 30 days' '3+ sellers with 30+/30d' 'tabard apron'
GD 'GD-20261106-19' 'DAB aerial' $null 'UNKNOWN' 3.45 'ZIK 248 sold, average 3.45' 'price' 'average 3.45, too low' 'profit of at least GBP 1' 'dab aerial'
GD 'GD-20261106-20' 'Litter picker grabber' $null 'UNKNOWN' 6.99 'ZIK 272 sold, average 6.99' 'price' 'average 6.99, too low for the cost' 'profit of at least GBP 1' 'litter picker'
GD 'GD-20261106-21' 'LED desk lamp' $null 'UNKNOWN' 8.08 'ZIK 339 sold, average 8.08' 'price' 'average 8.08, not pursued' 'profit of at least GBP 1' 'led desk lamp'
GD 'GD-20261106-22' 'Organ cat scratcher' $null 'UNKNOWN' $null 'ZIK 93 sold' 'demand' '93 sold in 30 days' '3+ sellers with 30+/30d' 'cat scratcher'
GD 'GD-20261106-23' 'Wireless doorbell 38 melodies (EPB-75191)' 8.85 'UNKNOWN' 14.99 'claoner-shopuk 14.99 (78/30d)' 'profit' 'ROI about 18.9% at 14.99; needs about 15.12' '20% ROI or 30% margin from GBP 8' 'wireless doorbell plug in'
Rec @{ id = 'AX-20261106-24'; cat = 'REJECTED'; kind = 'ali'; name = 'Hanging gazebo bird feeder (AliExpress Choice)'; cost = 4.38; costNote = 'deal price 4.38, reverts to about 10.01 in 24h'; ebayPrice = 7.85
    refNote = 'eBay active exact gazebo 29, umbrella 85; best 28/30d'; failedRule = 'strong_sellers'; seen = 'no gazebo/umbrella seller reaches 30+ sales in 30 days (max 28)'; limit = '3+ sellers with 30+/30d'
    reason = 'Strong-seller gate fails; deal price reverts'; mayChange = 'yes'; status = 'WATCH'; seasonality = 'evergreen'; target = 'NONE'; compliance = 'COMPLIANCE_REVIEW'; searchQ = 'gazebo hanging wild bird feeder' }
Rec @{ id = 'ZK-20261106-25'; cat = 'REJECTED'; kind = 'none'; name = 'Fidget toys pack'; failedRule = 'avoid'; seen = '700 sold, average 6.63, mostly branded NeeDoh / Schylling'; limit = 'no VeRO / branded matching'; reason = 'Branded market'; mayChange = 'no'; status = 'REJECTED'; seasonality = 'evergreen'; target = 'NONE' }
Rec @{ id = 'ZK-20261106-26'; cat = 'REJECTED'; kind = 'none'; name = 'Heated eye mask'; failedRule = 'demand'; seen = '110 sold in 30 days'; limit = '3+ sellers with 30+/30d'; reason = 'Low demand'; mayChange = 'yes'; status = 'REJECTED'; seasonality = 'evergreen'; target = 'NONE' }
