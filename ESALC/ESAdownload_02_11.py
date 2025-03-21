import cdsapi

c = cdsapi.Client()

c.retrieve(
    'satellite-land-cover',
    {
        'variable':'all',
        'format':'tgz',
        'year':[
            '2002','2003','2004',
            '2005','2006','2007',
            '2008','2009','2010',
            '2011'
        ],
        'version':'v2.0.7cds'
    },
    'download_02_11.tar.gz')
