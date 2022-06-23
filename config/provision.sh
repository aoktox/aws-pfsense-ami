#!/bin/sh

# replace <if></if> section of config.xml with proper names for running on AWS EC2
sed -i -E 's$<if>em0</if>$<if>ena0</if>$g' /conf/config.xml
sed -i -E 's$<if>em1</if>$<if>ena1</if>$g' /conf/config.xml
# Should be possible only have one interface for WAN but crash if not found em1 or ena1 FOR NOW ALWAYS TWO INTERFACES
#rm -rf /conf.default/config.xml
#cp /conf/config.xml /conf.default/config.xml
sed -i -E 's$<if>em0</if>$<if>ena0</if>$g' /conf.default/config.xml
sed -i -E 's$<if>em1</if>$<if>ena1</if>$g' /conf.default/config.xml

# print grep results for verification during packer build:
echo "grep -H <if> ... output:"
grep -H '<if>' /conf/config.xml
grep -H '<if>' /conf.default/config.xml
