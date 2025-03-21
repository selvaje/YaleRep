import cdsapi

c = cdsapi.Client()

c.retrieve(
    'satellite-land-cover',
    {
        'variable':'all',
        'format':'tgz',
        'year':[
            '2012','2013','2014',
            '2015','2016','2017',
            '2018'
        ],
        'version':[
            'v2.0.7cds','v2.1.1'
        ]
    },
    'download_12_18.tar.gz')
