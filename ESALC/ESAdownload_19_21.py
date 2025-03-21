import cdsapi

c = cdsapi.Client()

c.retrieve(
    'satellite-land-cover',
    {
        'variable':'all',
        'format':'tgz',
        'year':[
            '2019','2020','2021'
        ],
        'version':[
            'v2.1.1'
        ]
    },
    'download_19_21.tar.gz')
