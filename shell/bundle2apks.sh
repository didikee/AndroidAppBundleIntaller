# bundle2apks 转换指南
#
# 命令如下：
# java -jar /Users/dev01/Downloads/lunaon/bundletool.jar build-apks 
# --bundle=/Users/dev01/Downloads/lunaon/aifx-release/aifx-1.7-code25.aab 
# --output=/Users/dev01/Downloads/lunaon/aifx-release/aifx-1.7-code25.apks 
# --ks=/Users/dev01/AndroidFilters/CameraAndroid/app/keystore/aifx.jks 
# --ks-pass=pass:lunaon123!
# --ks-key-alias=aifx
# --key-pass=pass:lunaon123!
#
# 具体文档请参考：https://developer.android.com/studio/command-line/bundletool
# 
# 此脚本可以辅助你更方便的将app bundle 转换为apks
#

# 请配置bundlejar的文件路径
bundlejar_location="/Users/didikee/Downloads/lunaon/bundletool.jar";
# 请配置签名文件路径
ks_location="/Users/didikee/AndroidFilters/CameraAndroid/app/keystore/aifx.jks"
# 请配置签名密码
ks_pwd="lunaon123!";
# 请配置签名别名
ks_alias="aifx";
# 请配置签名别名密码
ks_alias_pwd="lunaon123!";

echo "请输入app bundle(app.aab)的文件路径："
read app_bundle

echo "请输入app apks 导出文件路径："
read apks_location


echo "执行日志: ";
echo "bundlejar 文件路径：$bundlejar_location";
echo "app bundle 文件路径：$app_bundle";
echo "apks 导出文件路径：$apks_location";
echo "执行中...";

java -jar $bundlejar_location build-apks --bundle=$app_bundle --output=$apks_location --ks=$ks_location --ks-pass=pass:$ks_pwd --ks-key-alias=$ks_alias --key-pass=pass:$ks_alias_pwd

echo "执行结束";  