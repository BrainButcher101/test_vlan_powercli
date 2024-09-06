from ipam.models import IPAddress
from extras.reports import Report

class DuplicateIPReport(Report):
    description = "Report showing only duplicate IP addresses"

    def test_duplicate_ips(self):
        # Dictionary to store IPs and their occurrences
        ip_dict = {}

        # Get all IP addresses from IPAM
        ip_addresses = IPAddress.objects.all()

        # Populate the dictionary with counts of each IP
        for ip in ip_addresses:
            ip_address = str(ip.address)
            if ip_address in ip_dict:
                ip_dict[ip_address].append(ip)
            else:
                ip_dict[ip_address] = [ip]

        # Identify duplicates and log only duplicate IPs
        for ip, occurrences in ip_dict.items():
            if len(occurrences) > 1:
                # Log only the duplicate IPs
                self.log_failure(
                    occurrences,
                    f"Duplicate IP address found: {ip} - assigned to {len(occurrences)} objects."
                )
