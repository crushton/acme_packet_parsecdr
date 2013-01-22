# Acme Packet Parse CDR

perl script to parse Acme Packet CDR files and add the AVP name to the
field

## Requirements

### Perl Modules
DBI  
DBD::SQLite

## Instructions
First run "createdb.pl" in order to create the SQLite database based off
the provided CSV files in the 'db' directory.

After the database is created, you can run "parsecdr.pl" on your CDR
file in order to update it. The output file will append "_out.csv" to
the end of it.

parsecdr.pl \<cdr filename\>

## Reference Materials

### Acme Packet Accounting Guides - Freely Available

[C610 Accounting
Guide](https://support.acmepacket.com/docs/PUB/SC610/Net-Net_4000_S-C6.1.0_ACLI_Accounting_Guide.pdf)  
[C620 Accounting
Guide](https://support.acmepacket.com/docs/PUB/SC620/Net-Net%204000%20S-C6.2.0%20Accounting%20Guide.pdf)  
[C630 Accounting
Guide](https://support.acmepacket.com/docs/PUB/SCX630/Net-Net%204000%20S-CX6.3.0%20Accounting%20Guide.pdf)  
[C640 Accounting
Guide](https://support.acmepacket.com/docs/PUB/SCX640/Net-Net%204000%20S-CX6.4.0%20Accounting%20Guide.pdf)  
[D700 Accounting
Guide](https://support.acmepacket.com/docs/PUB/SD700/Net-Net_9000_S-D7.0.0_Accounting_Guide.pdf)  
[D710 Accounting
Guide](https://support.acmepacket.com/docs/PUB/SD710/Net-Net%209000%20S-D7.1.0%20Accounting%20Guide.pdf) 

## Disclaimer
Although I am an employee of Acme Packet, the views expressed are my own
and do not represent the views of the company. The tools provided are
not officially
supported by Acme Packet. USE AT YOUR OWN RISK.

## License
Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
