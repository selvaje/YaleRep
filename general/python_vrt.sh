
GDAL_VRT_ENABLE_PYTHON=YES

<VRTDataset rasterXSize="1200" rasterYSize="1200">
  <SRS dataAxisToSRSAxisMapping="2,1">GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AXIS["Latitude",NORTH],AXIS["Longitude",EAST],AUTHORITY["EPSG","4326"]]</SRS>
  <GeoTransform>  6.0000000000000000e+00,  8.3333333333333339e-04,  0.0000000000000000e+00,  9.9991699999999994e+00,  0.0000000000000000e+00, -8.3264166666666617e-04</GeoTransform>
  <VRTRasterBand dataType="Byte" band="1" subClass="VRTDerivedRasterBand">
    <NoDataValue>255</NoDataValue>
    <ColorInterp>Gray</ColorInterp>
    <ComplexSource>
      <SourceFilename relativeToVRT="1">sb_site_4f375p.tiff</SourceFilename>
      <SourceBand>1</SourceBand>
      <SourceProperties RasterXSize="1200" RasterYSize="1200" DataType="Byte" BlockXSize="1200" BlockYSize="6" />
      <SrcRect xOff="0" yOff="0" xSize="1200" ySize="1200" />
      <DstRect xOff="0" yOff="0" xSize="1200" ySize="1200" />
      <NODATA>255</NODATA>
    </ComplexSource>
    <ComplexSource>
      <SourceFilename relativeToVRT="1">sb_site_m2cnfp.tiff</SourceFilename>
      <SourceBand>1</SourceBand>
      <SourceProperties RasterXSize="1200" RasterYSize="1200" DataType="Byte" BlockXSize="1200" BlockYSize="6" />
      <SrcRect xOff="0" yOff="0" xSize="1200" ySize="1200" />
      <DstRect xOff="0" yOff="0" xSize="1200" ySize="1200" />
      <NODATA>255</NODATA>
    </ComplexSource>
    <ComplexSource>
      <SourceFilename relativeToVRT="1">sb_site_muuoj7.tiff</SourceFilename>
      <SourceBand>1</SourceBand>
      <SourceProperties RasterXSize="1200" RasterYSize="1200" DataType="Byte" BlockXSize="1200" BlockYSize="6" />
      <SrcRect xOff="0" yOff="0" xSize="1200" ySize="1200" />
      <DstRect xOff="0" yOff="0" xSize="1200" ySize="1200" />
      <NODATA>255</NODATA>
    </ComplexSource>
  <PixelFunctionType>get_min</PixelFunctionType><PixelFunctionLanguage>Python</PixelFunctionLanguage><PixelFunctionCode>
<![CDATA[
import numpy as np

def get_min(in_ar, out_ar, xoff, yoff, xsize, ysize, raster_xsize,raster_ysize, buf_radius, gt, **kwargs):
    for a in in_ar:
        a[a==0] = 255
    np.minimum.reduce([a for a in in_ar], out=out_ar)
    print(np.unique(out_ar))
        ]]>
</PixelFunctionCode></VRTRasterBand>
</VRTDataset>
