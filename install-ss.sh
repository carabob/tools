#!/bin/sh
clear
model=$(cat /proc/xiaoqiang/model)

if [ "$model" == "R3G" -o "$model" == "R3P" ]; then
	echo "小米"$model"路由器插件安装程序"
	echo "========================="
	echo ""
else
        echo "对不起，本插件暂时只支持小米R3P、R3G路由器。"
        exit
fi

echo "开始下载安装包..."

curl -k -o /tmp/misstar-ss.tgz https://raw.githubusercontent.com/carabob/tools/master/misstar-ss.tgz

if [ $? -eq 0 ];then
    echo "安装包下载完成！"
else 
    echo "下载安装包失败，正在退出..."
    exit
fi

echo "开始解压安装包..."

tar -zxvf /tmp/misstar-ss.tgz -C /etc >/dev/null 2>&1

if [ $? -eq 0 ];then
    echo "解压完成，开始安装："
else 
    echo "解压失败，正在退出..."
    exit
fi

result=$(cat /etc/config/misstar | grep "config config 'ss'" | wc -l)
if [ "$result" == "0" ]; then
(
cat <<EOF
config config 'ss'
	option dns_mode 'pdnsd'
	option dns_port '53'
	option dns_red_ip 'lanip'
	option dns_red_enable '1'
	option version '1.0.8'
	option dns_server '8.8.8.8'
	option ss_acl_default_mode '1'
	option enable '0'
EOF
) >>/etc/config/misstar
fi

result=$(cat /etc/misstar/scripts/Monitor | grep "#misstar-ss" | wc -l)
if [ "$result" == "0" ]; then
(
cat <<EOF
#misstar-ss
App_enable=\$(uci get misstar.ss.enable)  #misstar-ss
if [ "\$App_enable" = '1' ];then  #misstar-ss
	result1=\$(ps | grep -E "ss-redir|ssr-redir" | grep -v 'grep' | grep -v script | wc -l)  #misstar-ss
	result2=\$(iptables -L -t nat  | grep SHADOWSOCKS | wc -l)
	if [ "\$result1" == "0" ] || [ "\$result2" == "0" ]; then #misstar-ss
		MTlog 3 "SS Process state Error,Try to restart it..."  #misstar-ss
		/etc/misstar/applications/ss/script/ss restart  #misstar-ss
	fi  #misstar-ss
	i=1  #misstar-ss
	while :  #misstar-ss
	do  #misstar-ss
		ss_status=\$(/etc/misstar/applications/ss/script/ss status)   #misstar-ss
		if [ "\$ss_status" = '2' ];then  #misstar-ss
			break  #misstar-ss
		fi  #misstar-ss
		sleep 10  #misstar-ss
		if [ "\$i" = '3' ];then #misstar-ss
			/etc/misstar/applications/ss/script/ss restart  #misstar-ss
			break #misstar-ss
		fi  #misstar-ss
		i=\`expr \$i + 1\`  #misstar-ss
	done  #misstar-ss
fi #misstar-ss
EOF
) >>/etc/misstar/scripts/Monitor
fi

result=$(cat /etc/misstar/scripts/file_check | grep "#misstar-ss" | wc -l)
if [ "$result" == "0" ]; then
(
cat <<EOF
#misstar-ss
result=\$(cat /usr/lib/lua/luci/controller/web/index.lua | grep applications/ss | wc -l) #misstar-ss
if [ \$result == 0 ]; then #misstar-ss
	cp -rf /usr/lib/lua/luci/controller/web/index.lua /tmp/ #misstar-ss
	sed -i "/"topograph"/a\\\\  entry({\\"web\", \\"misstar\", \\"ss\"}, template(\\"web/setting/applications/ss/html/ss\\"), _(\\"实用工具\\"), 85)" /tmp/index.lua #misstar-ss
	mv /tmp/index.lua /usr/lib/lua/luci/controller/web/index.lua #misstar-ss
	ln -s /etc/misstar/applications/ss/html/ss.lua /usr/lib/lua/luci/controller/api/ #misstar-ss
	rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/* #misstar-ss
fi #misstar-ss
EOF
) >>/etc/misstar/scripts/file_check
fi

result=$(cat /etc/misstar/scripts/Dayjob | grep "/etc/misstar/applications/ss/script/ss restart" | wc -l)
if [ "$result" == "0" ]; then
(
cat <<EOF
/etc/misstar/applications/ss/script/ss restart
EOF
) >>/etc/misstar/scripts/Dayjob
fi

result=$(cat /etc/misstar/luci/js/nav.json | grep "\"describe\":\"socket" | wc -l)
if [ "$result" == "0" ]; then
	sed -i 's/"children": \[/"children": \[{"title":"科学上网","version":"1.0.8","describe":"socket代理插件，支持TCP\\\/UDP","icon":"\&#xe609","href":"ss","versionlog":"修复大部分漏洞"},/g' /etc/misstar/luci/js/nav.json
fi

/etc/misstar/scripts/file_check
if [ $? -eq 0 ];then
    echo "安装完成，请刷新网页。"
else
    echo "安装失败，正在退出..."
    exit
fi

rm -rf /tmp/misstar-ss.tgz
rm -rf /tmp/install-ss.sh
