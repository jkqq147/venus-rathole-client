import QtQuick 1.1
import com.victron.velib 1.0

MbPage {

	title: qsTr("Rathole")

	model: VisibleItemModel {
		MbItemValue {
			description: qsTr("Status")
			item.bind: "com.victronenergy.rathole/StatusText"
		}

		MbItemOptions {
			description: qsTr("Client")
			bind: "com.victronenergy.rathole/Enabled"
			possibleValues: [
				MbOption { description: qsTr("Enabled"); value: 1 },
				MbOption { description: qsTr("Disabled"); value: 0 }
			]
		}

		MbItemValue {
			description: qsTr("Server")
			item.bind: "com.victronenergy.rathole/ServerAddress"
		}

		MbItemValue {
			description: qsTr("Device token")
			item.bind: "com.victronenergy.rathole/Token"
		}

		MbItemValue {
			description: qsTr("Targets")
			item.bind: "com.victronenergy.rathole/TargetCount"
		}
	}
}
