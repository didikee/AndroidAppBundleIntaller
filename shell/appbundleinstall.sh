# appbundle install 辅助脚本
# 脚本执行过程
# 1. app bundle --》 apks
# 2. install apks to android device
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

##################################

echo "请输入app bundle(app.aab)的文件路径："
read app_bundle

# /Users/didikee/Downloads/Android/aab/
# /Users/didikee/Downloads/Android/apks/
aab_folder="/Users/$USER/Downloads/Android/aab/";
apks_folder="/Users/$USER/Downloads/Android/apks/";

apks_file_name=$(basename "$app_bundle" ".aab")
# echo "apks文件名: $apks_file_name";

apks_location="$apks_folder${apks_file_name}.apks";
echo "apks输出目录: $apks_location";

# delete old file if exist
[ -e $apks_location ] && rm $apks_location


echo "正在处理app bundle 转 apks..."
# app bundle to apks
java -jar $bundlejar_location build-apks --bundle=$app_bundle --output=$apks_location --ks=$ks_location --ks-pass=pass:$ks_pwd --ks-key-alias=$ks_alias --key-pass=pass:$ks_alias_pwd

if [ ! -e $apks_location ]; then
	echo "生成apks出错!"
	echo "已退出."
	exit
fi

echo "正在安装apks..."
# install apks to android device
java -jar $bundlejar_location install-apks --apks=$apks_location

echo "安装完成"
echo "执行结束"; 


