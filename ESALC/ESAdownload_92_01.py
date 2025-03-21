import cdsapi

c = cdsapi.Client()

c.retrieve(
    'satellite-land-cover',
    {
        'variable':'all',
        'format':'tgz',
        'year':[
            '1992','1993','1994',
            '1995','1996','1997',
            '1998','1999','2000',
            '2001'
        ],
        'version':'v2.0.7cds'
    },
    'download_92_01.tar.gz')
