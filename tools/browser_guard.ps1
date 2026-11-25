<#
Browser safety guard for the eBay Product Hunter project (RESEARCH ONLY).
Runs as a Claude Code PreToolUse hook for every mcp__claude-in-chrome__* tool (see .claude/settings.json).
Reads the hook JSON from stdin. To block, it prints a PreToolUse "deny" decision; otherwise it prints nothing,
and the normal Claude Code / Claude in Chrome permission prompts still apply.

Layers (any one can block):
  1. Disabled tools: javascript_tool, file_upload, upload_image, shortcuts_execute (also inside browser_batch).
  2. URL layer: navigation only to config.yaml browser.approved_domains (and subdomains), and never to
     checkout / basket / payment / order / selling / listing / offer / bid / messaging / feedback / watchlist /
     account / sign-up / subscription / upgrade pages. Non-web schemes are blocked.
  3. Action layer: clicks, key presses, typing and form input must carry a description (action_summary), and are
     blocked when it describes a forbidden action (buy, basket, checkout, pay, order, bid, offer, list, publish,
     revise, end listing, price change, ads, message, feedback, watchlist, account, subscription, terms,
     CAPTCHA/security, proxy/evasion). Typing card numbers or credentials is blocked.
  4. Tab layer: interaction is blocked on a tab whose last known address (from navigate) is a forbidden page
     or an unapproved domain. Note: clicks are sent as screen positions, so layers 3-4 cannot see the element;
     the Claude Code permission prompt for browser actions remains a human backstop.
  5. Narrow basket exception (user decision 2026-10-04): only while .claude/basket_clear_approval.json is unexpired
     (written after the user approves a specific clean-up list), the agent may open exactly amazon.co.uk/gp/cart/view.html
     and click 'Deletes <item> from the basket'. Nothing else on that page; no basket action anywhere else.
     Seller Sprite 'View details' clicks are always denied (user rule 2026-10-05; was allowed on product pages 2026-10-04).
Fails CLOSED: any guard error blocks the action.
Decisions are logged (without typed text) to data/evidence/browser_guard_log.csv.

Manual test:  '{"tool_name":"mcp__claude-in-chrome__navigate","tool_input":{"url":"https://www.ebay.co.uk"}}' | powershell -File tools\browser_guard.ps1
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if ($env:BROWSER_GUARD_TEST_ROOT) { $root = $env:BROWSER_GUARD_TEST_ROOT }   # tests only: isolated config/state/log
$statePath = Join-Path $root '.claude\browser_guard_state.json'
$logPath = Join-Path $root 'data\evidence\browser_guard_log.csv'

function Write-Log([string]$tool, [string]$action, [string]$decision, [string]$reason, [string]$detail) {
    try {
        $dir = Split-Path $logPath -Parent
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $row = [pscustomobject][ordered]@{ time_uk = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, [TimeZoneInfo]::FindSystemTimeZoneById('GMT Standard Time')).ToString('yyyy-MM-dd HH:mm:ss')
            tool = $tool; action = $action; decision = $decision; reason = $reason; detail = $detail }
        $row | Export-Csv -LiteralPath $logPath -NoTypeInformation -Append -Encoding UTF8
    } catch { }
}
function Deny([string]$reason, [string]$tool, [string]$action, [string]$detail) {
    Write-Log $tool $action 'DENY' $reason $detail
    $out = @{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'
            permissionDecisionReason = "eBay Product Hunter browser guard (research only): $reason" } }
    [Console]::Out.Write(($out | ConvertTo-Json -Compress -Depth 5))
    exit 0
}

# --- Rules -------------------------------------------------------------------
$DISABLED = @('javascript_tool', 'file_upload', 'upload_image', 'shortcuts_execute')
$INTERACT = @('left_click', 'right_click', 'double_click', 'triple_click', 'left_click_drag', 'key', 'type')

# URL patterns that are never opened (checked on the full URL, including query and #fragment), lower case.
$URL_BLOCK = [ordered]@{
    'checkout/cart/basket' = 'checkout|/cart(?![a-z])|shoppingcart|/basket|trolley|/gp/buy|/gp/cart|/buy/spc|/bin/|addtocart|add-to-cart|add_to_cart'
    'payment/order'        = '(^|[/.])pay\.|payments?[/.]|/payment|paypal|/order/confirm|trade/confirm|/trade/buy|confirm_?order|place-?order|placeorder|/wallet|payment-method|billing'
    'selling/listing'      = 'sellercentral|/sl/|/lstng|/sh/(lst|ord|mkt|prf|acct|fin)|/sell(/|\?|$)|bulksell|sellsimilar|sell-similar|/import|/lister|bulk-?lister|/listing/(create|new|edit)'
    'offers/bids'          = 'offer\.ebay|makeoffer|/bo/|bid\.ebay|/bfl/|placebid|/bid(/|\?|$)'
    'messaging/feedback'   = 'mesg\.ebay|/msg(/|\?|$)|/messages|/cnt/|contactseller|contact-seller|/fdbk/leave|leavefeedback|/review/(write|create)|write-a-review'
    'watchlist/saved'      = 'watchlist|/mye/myebay/(watch|saved)|/hz/wishlist|followseller'
    'account/sign-up'      = 'sign-?up|/register|registration|/ap/register|/account/settings|/settings(/|\?|$)|my-account|/myaccount'
    'subscription/upgrade' = 'subscri|upgrade|/pricing|/plans?(/|\?|$)|/trial|buy-?credits|top-?up|prime/signup|/gp/subs'
    'delivery-slot'        = 'delivery-?slot|book-?slot|/slots(/|\?|$)'
    'keepa-tracking'       = 'keepa\.com.*(tracking|#!manage)'
}
# Action descriptions (action_summary) that describe a forbidden action, lower case.
$ACT_BLOCK = [ordered]@{
    'buying'              = '\bbuy(s|ing)?\b|\bpurchas'
    'basket/cart/trolley' = '\b(add|adds|added|adding|move|moves|put|puts)\b[^.]{0,30}\b(basket|cart|trolley|bag)\b|\b(basket|cart|trolley)\s+(page|icon|button|link)|\b(view|views|open|opens|go to|goes to)\s+(the\s+|your\s+)?(basket|cart|trolley)\b'
    'checkout'            = 'check\s?-?out'
    'sellersprite stock (adds to basket)' = 'view details|stock (status )?(panel|details)|sellersprite.{0,20}(stock|details)'
    'payment'             = '\bpay(s|ing|ment|pal)?\b|card (number|details)|\bcvv\b|\bcvc\b|billing'
    'placing orders'      = 'place[sd]?\s+(the\s+|your\s+|an\s+|this\s+)?order|order now|confirm (and|&) pay|complete (the )?purchase|1-click|one-click|subscribe\s*(&|and)\s*save|book (a |the )?(delivery )?slot'
    'bids'                = '\bbids?\b|\bbidding\b'
    'offers'              = 'make (an )?offer|best offer|submit (an |the )?offer|send (an |the )?offer|counter ?offer'
    'listing creation'    = 'create[sd]?\s+(a |the |new )?listing|\blist (it|this|the item|an item|item|now)\b|\bsell (it|this|similar|one like|an item)\b|sell similar|start selling|\b(upload|uploads|uploading|import|imports|importing|export|exports|push|pushes|send|sends|copy|copies|list|lists)\b[^.]{0,30}\b(to|on|onto|into)\s+(my\s+|the\s+)?(ebay|shopify|store)\b|upload on ebay|title builder'
    'publishing'          = 'publish|go live|(submit|post)s? (the )?listing'
    'listing revision'    = '\brevis|edit(s)? (the |this )?listing|bulk edit|update(s)? (the |this )?listing'
    'ending listings'     = 'end(s)? (the |this )?(listing|item)|\brelist|delete(s)? (the |this )?listing'
    'price changes'       = '(change|edit|update|lower|raise|set|reduce)[sd]?\s+(the |my |its )?(price|pricing)'
    'advertising changes' = 'promot(e|ed|ion setting)|ad rate|advert|campaign|\bboost'
    'messaging'           = 'send(s)? (a |the )?message|message (the )?(seller|buyer)|contact(s)? (the )?(seller|buyer)|ask(s)? (a |the )?(seller )?question|reply to'
    'feedback'            = '(leave|leaves|submit|submits|give|gives|post|posts|write|writes)\s+(a\s+)?(feedback|review)'
    'watchlist'           = 'watchlist|add(s)? to (the )?watch|watch (this |the )?item|unwatch|save(s)? (this |the )?(search|seller|item)|follow(s)? (this |the )?(seller|store)|add(s)? to (a |my )?(list|wish ?list)'
    'account creation'    = 'sign\s?-?up|create(s)? (an |a new )?account|register(s)? (an |a )?account|registration|join (now|free)'
    'subscriptions/upgrades' = 'subscri|upgrade|start(s|ing)?\s+(a\s+|your\s+|the\s+)?(free\s+)?trial|free trial|buy credits|top.?up|(choose|select|change)(s)?\s+(a\s+|the\s+)?plan'
    'accepting terms'     = 'accept(s)? (all|the)? ?(cookies|terms|agreement|conditions)|agree(s)? to'
    'CAPTCHA/security bypass' = 'captcha|not a robot|robot check|verify (you|that you|human)|slider|puzzle|security check|challenge|one.?time (code|password)|\botp\b|\b2fa\b|two.?factor|verification code|security code'
    'proxy/anti-bot evasion' = 'proxy|\bvpn\b|user.?agent|incognito|clear(s)? (the )?cookies|fingerprint|spoof'
    'downloads'           = '\bdownload'
    'signing in (user only, s23)' = '\b(sign|signs|signing|log|logs|logging)\s?-?(in|on)\b|\bsign into\b|\blog into\b|continue with (google|facebook|apple|amazon)'
    'pop-up call-to-action' ='shop now|claim(s)? (the |your |a )?(coupon|offer|deal|reward|voucher|gift)|install(s)? (the )?app|get (the )?app|redeem|spin(s)? (the )?wheel|join (prime|now|free)'
}
# Research phrases that contain blocked words but are safe (removed before the action check).
$SAFE_PHRASES = 'buy it now\s*(filter|format|option|tab|checkbox|only|listings?|results?|toggle|box)?|buy box|best ?sellers?|bought in (the )?past month|frequently bought|other sellers|price (history|chart|filter|range|graph)|sold (items|listings) filter' +
    # User rule (2026-10-03): close pop-ups. "Closes/dismisses the <...> pop-up/banner/dialog" is safe, whatever the pop-up advertises.
    '|\b(close|closes|closing|dismiss|dismisses|dismissing)\s+(the\s+|a\s+|this\s+)?[a-z0-9 &''-]{0,40}?(pop-?ups?|banner|dialog|modal|overlay|promo(tion)?( box)?|offer box|notification)\b' +
    '|\bwithout (signing|logging) (in|on)\b' +
    '|\b(no,? thanks|not now|maybe later)\b[a-z0-9 &''-]{0,40}?(pop-?ups?|banner|dialog|modal|overlay|prompt)\b'
# --- Narrow basket exception (user decision 2026-10-04, option 2) -------------------------------------
# Seller Sprite's stock check adds units to the Amazon basket. The ONLY basket permission:
#   * open exactly https://www.amazon.co.uk/gp/cart/view.html, and
#   * click "Deletes <item> from the basket",
# and ONLY while .claude/basket_clear_approval.json exists and has not expired. The agent writes that file
# only after the user has said yes to a specific clean-up list in chat, and it expires 15 minutes later.
# Every other basket, checkout, buy, payment and order rule stays exactly as strict as before.
$CART_VIEW_RE = '^https://www\.amazon\.co\.uk/gp/cart/view\.html(\?[^#]*)?$'
$DELETE_RE    = '^\s*deletes?\s+(the\s+)?[a-z0-9 ,.()&''x×-]{1,120}\s+(line\s+)?from\s+(the\s+)?(amazon\s+)?basket\s*$'
$DELETE_NEVER = 'check\s?-?out|proceed|buy|order|pay|save for later|quantity|\bqty\b|gift|subscribe|add|move|update|increase|decrease|coupon|voucher'
$SS_STOCK_RE  = 'view details|stock (status )?(panel|details)|sellersprite.{0,20}(stock|details)'
$approvalPath = Join-Path $root '.claude\basket_clear_approval.json'
function Test-BasketApproval {
    if (-not (Test-Path -LiteralPath $approvalPath)) { return $false }
    try { $a = Get-Content -Raw -LiteralPath $approvalPath | ConvertFrom-Json; return ([DateTime]::Parse("$($a.expires_utc)").ToUniversalTime() -gt [DateTime]::UtcNow) } catch { return $false }
}
# Typing / form text: credentials are never entered by the agent.
$CRED_BLOCK = 'password|passcode|\bpin\b|username|e-?mail address|sign ?in|log ?in|credential|security code|one.?time|verification code|card (number|details)|\bcvv\b|\bcvc\b|expiry'

function Test-Luhn([string]$digits) {
    $sum = 0; $alt = $false
    for ($i = $digits.Length - 1; $i -ge 0; $i--) { $d = [int][string]$digits[$i]; if ($alt) { $d *= 2; if ($d -gt 9) { $d -= 9 } }; $sum += $d; $alt = -not $alt }
    return ($sum % 10 -eq 0)
}
function Test-CardNumber([string]$text) {
    foreach ($m in [regex]::Matches("$text", '(?<!\d)(?:\d[ -]?){12,18}\d(?!\d)')) {
        $d = $m.Value -replace '[ -]', ''
        if ($d.Length -ge 14 -and $d.Length -le 19 -and (Test-Luhn $d)) { return $true }   # 13-digit EAN/GTIN codes are allowed
    }
    return $false
}
function Get-ApprovedDomains {
    $cfg = Get-Content -Raw -LiteralPath (Join-Path $root 'config.yaml')
    $m = [regex]::Match($cfg, '(?m)^\s+approved_domains:\s*\[([^\]]*)\]')
    if (-not $m.Success) { return @() }
    return @($m.Groups[1].Value -split ',' | ForEach-Object { $_.Trim().Trim('"', "'").ToLower() } | Where-Object { $_ })
}
function Test-Url([string]$url) {
    # Returns $null if allowed, otherwise the reason.
    $u = "$url".Trim()
    if ($u -in 'back', 'forward') { return $null }
    if ($u -match '^(javascript|data|file|chrome|chrome-extension|edge|about|view-source|blob|ftp):') { return "non-web address scheme ($($u.Split(':')[0]))" }
    if ($u -notmatch '^[a-z][a-z0-9+.-]*://') { $u = "https://$u" }
    try { $uri = [Uri]$u } catch { return 'unreadable URL' }
    if ($uri.Scheme -notin 'http', 'https') { return "non-web address scheme ($($uri.Scheme))" }
    $h = $uri.Host.ToLower()
    $ok = $false; foreach ($d in $script:Domains) { if ($h -eq $d -or $h.EndsWith(".$d")) { $ok = $true; break } }
    if (-not $ok) { return "domain '$h' is not an approved research site (config.yaml browser.approved_domains)" }
    $full = $u.ToLower()
    foreach ($k in $URL_BLOCK.Keys) { if ($full -match $URL_BLOCK[$k]) { return "forbidden page type: $k" } }
    return $null
}
function Test-Summary([string]$summary) {
    $s = " $("$summary".ToLower()) "
    $s = [regex]::Replace($s, $SAFE_PHRASES, ' ')
    foreach ($k in $ACT_BLOCK.Keys) { if ($s -match $ACT_BLOCK[$k]) { return "forbidden action: $k" } }
    return $null
}

try {
    [Console]::InputEncoding = [Text.Encoding]::UTF8
    $raw = [Console]::In.ReadToEnd()
    $evt = $raw | ConvertFrom-Json
    $toolFull = "$($evt.tool_name)"
    $tool = $toolFull -replace '^mcp__claude-in-chrome__', ''
    $script:Domains = Get-ApprovedDomains
    $state = @{}
    if (Test-Path -LiteralPath $statePath) { try { $j = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json; foreach ($p in $j.PSObject.Properties) { $state[$p.Name] = "$($p.Value)" } } catch { } }

    # Expand browser_batch into its items; everything else is a single item.
    $items = @()
    if ($tool -eq 'browser_batch') { foreach ($a in @($evt.tool_input.actions)) { $nm = ("$($a.name)" -replace '^mcp__claude-in-chrome__', ''); $items += , @($nm, $a.input) } }
    else { $items += , @($tool, $evt.tool_input) }

    $newState = @{} + $state
    foreach ($it in $items) {
        $t = $it[0]; $in = $it[1]
        if ($t -in $DISABLED) { Deny "the '$t' tool is disabled for this project" $toolFull $t '' }
        $act = if ($in -and $in.PSObject.Properties.Name -contains 'action') { "$($in.action)" } else { '' }
        $tab = if ($in -and $in.PSObject.Properties.Name -contains 'tabId') { "$($in.tabId)" } else { '' }
        $summary = if ($in -and $in.PSObject.Properties.Name -contains 'action_summary') { "$($in.action_summary)" } else { '' }

        # Layer 2: any URL argument (navigate, tab creation, etc.)
        if ($in -and $in.PSObject.Properties.Name -contains 'url' -and "$($in.url)") {
            $why = Test-Url "$($in.url)"
            # Basket exception: only the basket view page, only while a user-approved clean-up is active.
            if ($why -and "$($in.url)".Trim() -match $CART_VIEW_RE -and $t -eq 'navigate' -and (Test-BasketApproval)) { $why = $null }
            if ($why) { Deny "blocked navigation to $($in.url) - $why" $toolFull $t "$($in.url)" }
            if ($tab -and "$($in.url)" -notin 'back', 'forward') { $newState[$tab] = "$($in.url)" }
            if ("$($in.url)" -in 'back', 'forward' -and $tab) { $newState.Remove($tab) }   # unknown page after history navigation
        }

        $isInteract = ($t -eq 'computer' -and $act -in $INTERACT) -or $t -eq 'form_input'
        if ($isInteract) {
            # Layer 3: description required and checked
            if (-not $summary.Trim()) { Deny "a '$t/$act' action must state what it does (action_summary)" $toolFull $act '' }
            $tabUrl = if ($tab -and $state.ContainsKey($tab)) { $state[$tab] } else { '' }
            $sl = $summary.ToLower()
            # Basket page: the ONLY allowed interaction is a single left click that deletes a basket line,
            # while a user-approved clean-up is active. Everything else on that page is denied.
            if ($tabUrl -match $CART_VIEW_RE) {
                if (-not (Test-BasketApproval)) { Deny 'basket page: no active user-approved clean-up' $toolFull $act $summary }
                if ($t -ne 'computer' -or $act -ne 'left_click') { Deny "basket page: only a delete click is allowed (not '$act')" $toolFull $act $summary }
                if ($sl -notmatch $DELETE_RE -or $sl -match $DELETE_NEVER) { Deny "basket page: only 'Deletes <item> from the basket' is allowed ('$summary')" $toolFull $act $summary }
                continue   # this one delete click is allowed; layers 3-4 are not applied to it
            }
            # Seller Sprite stock "View details": never clicked (user rule 2026-10-05, CLAUDE.md s5.2; it adds
            # units to the basket and slows research). Seller type and stock are read from the visible summary only.
            if ($sl -match $SS_STOCK_RE) { Deny "Seller Sprite 'View details' is never clicked (user rule 2026-10-05) ('$summary')" $toolFull $act $summary }
            # Outside the approved basket page, no action may touch a basket in any way (incl. deletes).
            if ($sl -match '\b(basket|cart|trolley)\b') { Deny "basket actions are only allowed on the approved basket page ('$summary')" $toolFull $act $summary }
            $why = Test-Summary $summary
            if ($why) { Deny "$why ('$summary')" $toolFull $act $summary }
            $text = if ($t -eq 'form_input') { "$($in.value)" } elseif ($act -eq 'type') { "$($in.text)" } else { '' }
            if ($text) {
                if (Test-CardNumber $text) { Deny 'card/payment number entry' $toolFull $act $summary }
                if ($summary.ToLower() -match $CRED_BLOCK) { Deny 'password/credential or security-code entry (the user enters these)' $toolFull $act $summary }
            }
            # Layer 4: the tab's last known page
            if ($tab -and $state.ContainsKey($tab)) {
                $why = Test-Url $state[$tab]
                if ($why) { Deny "interaction on a forbidden page ($($state[$tab])) - $why" $toolFull $act $summary }
            }
        }
    }

    # Remember tab addresses for layer 4 (only reached when nothing was denied).
    if ($newState.Count -ne $state.Count -or @($newState.Keys | Where-Object { $newState[$_] -ne $state[$_] }).Count) {
        $dir = Split-Path $statePath -Parent; if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ($newState | ConvertTo-Json -Compress) | Set-Content -LiteralPath $statePath -Encoding UTF8
    }
    Write-Log $toolFull (@($items | ForEach-Object { $_[0] }) -join '+') 'ALLOW' '' ''
    exit 0
} catch {
    Deny "guard error, failing closed ($($_.Exception.Message))" "$($evt.tool_name)" '' ''
}
