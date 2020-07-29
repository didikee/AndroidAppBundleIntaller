# Android app bundle 安卓指南
# 
# java -jar /Users/didikee/Downloads/lunaon/bundletool.jar install-apks --apks=/Users/didikee/Downloads/lunaon/aifx-release/aifx-3.8-code60.apks

# 请配置bundlejar的文件路径
bundlejar_location="/Users/didikee/Downloads/lunaon/bundletool.jar";


echo "请输入apks的文件路径："
read apks_location

apk_file_name=$(basename "$apks_location" ".apks")

echo "获取文件名：$apk_file_name"


echo "执行日志: ";
echo "bundlejar 文件路径：$bundlejar_location";
echo "apks 文件路径：$apks_location";
echo "执行中...";

echo $USER
# /Users/didikee/Downloads/Android/aab
# /Users/didikee/Downloads/Android/apks

#java -jar $bundlejar_location install-apks --apks=$apks_location

echo "执行结束";  