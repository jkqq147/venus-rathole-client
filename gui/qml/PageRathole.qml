import QtQuick 1.1
import com.victron.velib 1.0

MbPage {
	id: root
	property VBusItem guiLanguage: VBusItem { bind: "com.victronenergy.settings/Settings/Gui/Language" }
	property VBusItem statusItem: VBusItem { bind: "com.victronenergy.rathole/StatusText" }
	property bool isChinese: guiLanguage.valid && guiLanguage.value === "zh"

	function statusText(value) {
		if (!root.isChinese)
			return value
		return value === "Client running" ? "运行中" : value === "Disabled" ? "已停用" : value === "Configuration required" ? "需要配置" : value === "Starting" ? "启动中" : value === "Starting client" ? "正在启动" : value === "Restarting client" ? "正在重启" : value === "Start failed" ? "启动失败" : value
	}

	title: qsTr("Rathole")

	model: VisibleItemModel {
		MbItemValue {
			description: root.isChinese ? "状态" : qsTr("Status")
			item: VBusItem { value: root.statusText(root.statusItem.value) }
		}

		MbItemOptions {
			description: root.isChinese ? "客户端" : qsTr("Client")
			bind: "com.victronenergy.rathole/Enabled"
			possibleValues: [
				MbOption { description: root.isChinese ? "启用" : qsTr("Enabled"); value: 1 },
				MbOption { description: root.isChinese ? "停用" : qsTr("Disabled"); value: 0 }
			]
		}

		MbItemValue {
			description: root.isChinese ? "服务器" : qsTr("Server")
			item.bind: "com.victronenergy.rathole/ServerAddress"
		}

		MbItemValue {
			description: root.isChinese ? "设备 Token" : qsTr("Device token")
			item.bind: "com.victronenergy.rathole/Token"
		}

		MbItemValue {
			description: root.isChinese ? "目标服务" : qsTr("Targets")
			item.bind: "com.victronenergy.rathole/TargetCount"
		}
	}
}
