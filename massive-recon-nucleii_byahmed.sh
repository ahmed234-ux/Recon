#!/bin/bash
# Ahmed tell you have a nice haking
# List of domains for recon
domains=(
    "👀put your domain👀"
)

output="full_recon"
mkdir -p $output

# Step 1: Subdomain Enumeration using various tools
for domain in "${domains[@]}"; do
    echo "🔎 Starting recon on: $domain"
    outdir="$output/$domain"
    mkdir -p $outdir

    # 1.1 Using Sublist3r
    echo "[*] Running Sublist3r..."
    sublist3r -d $domain -b -t 50 -v -o $outdir/sublist3r.txt

    # 1.2 Using ShodanX
    echo "[*] Running ShodanX..."
    source ~/shodanx-env/bin/activate
    shodanx subdomain -d $domain > $outdir/shodanx.txt

    # 1.3 Using Subextreme
    echo "[*] Running Subextreme..."
    subextreme -w /usr/share/seclists/Discovery/DNS/n0kovo_subdomains.txt -d $domain -c 100 -o $outdir/subextreme.txt

    # 1.4 Using Subfinder
    echo "[*] Running Subfinder..."
    subfinder -d $domain -all -silent > $outdir/subfinder.txt

    # Combine subdomains
    echo "[*] Combining subdomains..."
    cat $outdir/sublist3r.txt $outdir/shodanx.txt $outdir/subextreme.txt $outdir/subfinder.txt | urldedupe -s > $outdir/subdomains.txt

    # Step 2: Filtering live subdomains with httpx
    echo "[*] Running httpx..."
    httpx -l $outdir/subdomains.txt -o $outdir/live_subdomains.txt -t 60 -random-agent -mc 200

    # Step 3: Using Waybackurls to find archived URLs
    echo "[*] Running Waybackurls..."
    cat $outdir/subdomains.txt | waybackurls > $outdir/wayback_urls.txt

    # Step 4: Dedupe all URLs and filter unique ones
    cat $outdir/wayback_urls.txt | urldedupe -s > $outdir/unique_urls.txt

    # Step 5: Parameter discovery using Arjun
    echo "[*] Running Arjun to find hidden parameters..."
    arjun -i $outdir/unique_urls.txt -t 10 -c 300 -T 30 -d 10 -oB 127.0.0.1:8080 -m POST -oT $outdir/hidden_params.txt

    # Step 6: XSS Testing with Dalfox
    echo "[*] Running Dalfox to check for XSS..."
    dalfox file $outdir/unique_urls.txt --waf-evasion --user-agent 'Mozilla/5.0' --timeout 30 --proxy 'http://127.0.0.1:8080' -b '"><img src=x onerror=eval(atob(this.id))>' -o $outdir/xss_found.txt

    # Step 7: Searching for hidden files with Dirsearch
    echo "[*] Running Dirsearch to find hidden files..."
    dirsearch -u https://$domain -e 'conf,config,bak,backup,smp,old,db,sql,asp,aspx,py,rb,php,bhp,cache,cgi,csv,html,inc,jar,js,json,jsp,lock,log,rar,sql.qz,sql.zip,sql,tar,tar.bz2,tt,wadl,zip,xml,swp,x~,asp~,py~,rb~,php~,bkp,jsp~,rar,gz,sql~,swp~wdl,env,ini' --full-url -delay=15 --timeout=30 -p 127.0.0.1:8080 --random-agent -t 50 -w /usr/share/seclists/Discovery/Web-Content/combined_words.txt -o $outdir/hidden_files.txt

    # Step 8: Looking for LFI vulnerabilities using GF
    echo "[*] Running GF to check for LFI..."
    cat $outdir/unique_urls.txt | gf lfi | tee $outdir/lfi_found.txt

    # Step 9: Caching Poising Testing with wcvs
    echo "[*] Running wcvs to test cache poisoning..."
    wcvs -u "https://$domain" -hw /usr/share/seclists/Miscellaneous/Web/http-request-headers/http-request-headers-common-standard-fields.txt -pw ~/wcvs-wordlists/parameters.txt -f > $outdir/cache_poisoning.txt

    # Step 10: Get IPs for subdomains using dnsx
    echo "[*] Getting IPs for subdomains..."
    cat $outdir/live_subdomains.txt | dnsx -a -ro -silent | anew $outdir/ip_subdomains.txt

    # Step 11: Screenshots of subdomains using Gowitness
    echo "[*] Taking screenshots of live subdomains..."
    cat $outdir/live_subdomains.txt | gowitness single -c $outdir/screenshots/

    echo "✅ Recon complete for $domain. Results are saved in $outdir"
done

echo "🚀 Full Recon completed for all domains!"
