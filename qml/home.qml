import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import Huestacean 1.0

Pane {
    id: home

    Column {
        anchors.fill: parent

		spacing: 10

		GroupBox {
			id: bridgesBox
			anchors.left: parent.left
			anchors.right: parent.right
			title: "Bridges"

			Column
			{
				anchors.left: parent.left
				anchors.right: parent.right
				spacing: 10

				Row {
					spacing: 10

					Button {
						text: qsTr("Search")
						onClicked: {
							searchIndicator.searching = true
							searchTimer.start()
							Huestacean.bridgeDiscovery.startSearch()
						}
					}

					BusyIndicator {
						id: searchIndicator
						property bool searching
						visible: searching
					}

					Timer {
						id: searchTimer
						interval: 5000;
						repeat: false
						onTriggered: searchIndicator.searching = false
					}
				}

				Component {
					id: bridgeDelegate

					Item {
						width: bridgesGrid.cellWidth
						height: bridgesGrid.cellHeight

						Rectangle {
							color: "#0FFFFFFF"
							radius: 10
							anchors.fill: parent
							anchors.margins: 5

							GridLayout {
								columns: 2
								anchors.fill: parent
								anchors.margins: 5

								Column {
									Layout.column: 0

									Label {
										font.bold: true
										text: modelData.friendlyName
									}

									Label {
										text: modelData.address
									}
						
									Label {
										text: modelData.id
									}

									Label {
										text: "Connected: " + modelData.connected
									}
								}

								Button {
									anchors.top: parent.top
									anchors.bottom: parent.bottom
									Layout.column: 1
									text: "Connect"
									visible: !modelData.connected && !modelData.wantsLinkButton

									onClicked: modelData.connectToBridge()
								}

								Button {
									anchors.top: parent.top
									anchors.bottom: parent.bottom
									Layout.column: 1
									text: "Link"
									visible: !modelData.connected && modelData.wantsLinkButton

									onClicked: {
										linkPopup.bridge = modelData
										linkPopup.open()
									}
								}

								Button {
									anchors.top: parent.top
									anchors.bottom: parent.bottom
									Layout.column: 1
									text: "Forget"
									visible: modelData.connected

									onClicked: modelData.resetConnection()
								}
							}
						}
					}
				}

				GridView {
					id: bridgesGrid
					clip: true
					anchors.left: parent.left
					anchors.right: parent.right
					height: 125

					cellWidth: 200; cellHeight: 100
					model: Huestacean.bridgeDiscovery.model
					delegate: bridgeDelegate

					ScrollBar.vertical: ScrollBar { contentItem.opacity: 1; }
				}

				Row {
					spacing: 10
					TextField {
						focus: true
						width: 150
						placeholderText: "0.0.0.0"
					}
					Button {
						text: "(TODO) Manually add IP"
					}
				}
			}
		}
		
		GroupBox {
			anchors.left: parent.left
			anchors.right: parent.right

			title: "Screen sync settings"

			Column {
				anchors.left: parent.left
				anchors.right: parent.right
				spacing: 10

				RowLayout {
					anchors.left: parent.left
					anchors.right: parent.right
					spacing: 20
					Column {
						Label {
							text: "Monitor"
						}

						Row {
							ComboBox {
								currentIndex: 0
								width: 200
								model: Huestacean.monitorsModel
								textRole: "asString"
								onCurrentIndexChanged: Huestacean.setActiveMonitor(currentIndex)
							}

							Button {
								text: "Redetect"
								onClicked: Huestacean.detectMonitors()
					
							}
						}

						//Rectangle { height: 200; width: 300; }
					}

					Column {
						Label {
							text: "Entertainment group"
						}

						Row {
							ComboBox {
								id: entertainmentComboBox
								currentIndex: 0
								width: 300
								model: Huestacean.entertainmentGroupsModel
								textRole: "asString"

								property var lights: undefined

								onModelChanged: {
									updateLights();
								}

								onCurrentIndexChanged: {
									updateLights()
								}

								function updateLights() {
									if(model) {
										if(lights) {
											for (var i in lights) {
												lights[i].destroy();
											}
										}

										lights = [];
										for(var i = 0; i < model[currentIndex].numLights(); i++) {
											var light = model[currentIndex].getLight(i);
											var l = lightComponent.createObject(groupImage);
											l.name = light.id;
											l.index = i
											l.setPos(light.x, light.z)
											lights.push(l);
										}
									}
								}
							}

							Button {
								text: "Redetect"
								onClicked: Huestacean.detectMonitors()
							}
						}

						Rectangle {
							color: "black"
							height: 220; 
							width: 220; 
							border.width: 1
							border.color: "#414141"

							Image { 
								anchors.centerIn: parent
								id: groupImage
								height: 200; width: 200; 
								source: "qrc:/images/egroup-xy.png"
							}
						}						
					}
				}

				Button {
					text: Huestacean.syncing ? "Stop sync" : "Start sync"
					onClicked: Huestacean.syncing ? Huestacean.stopScreenSync() : Huestacean.startScreenSync(entertainmentComboBox.model[entertainmentComboBox.currentIndex])
				}
			}
		}
    }

	Component {
        id: lightComponent

		Rectangle { 
			id: lightIcon
			color: "blue";
			height: 20; 
			width: 20; 
			radius: 5

			property var name: "INVALID"
			property var index: 0

			function setPos(inX, inY) {
				x = ((1 + inX) / 2.0) * groupImage.width - width/2
				y = ((1 - inY) / 2.0) * groupImage.height - height/2
			}

			Label {
				anchors.centerIn: parent
				text: lightIcon.name
			}

			MouseArea {
				id: mouseArea
				anchors.fill: parent
				drag.target: lightIcon
				drag.axis: Drag.XAndYAxis

				drag.minimumX: 0 - width/2
				drag.maximumX: groupImage.width - width/2

				drag.minimumY: 0 - height/2
				drag.maximumY: groupImage.height - height/2

				drag.onActiveChanged: {
					if(!drag.active) {
						var bridgeX = 2 * (lightIcon.x + lightIcon.width/2) / groupImage.width - 1
						var bridgeZ = 2 * (lightIcon.y + lightIcon.height/2) / groupImage.height + 1

						entertainmentComboBox.model[entertainmentComboBox.currentIndex].updateLightXZ(index, bridgeX, bridgeZ);
					}
				}
			}
		}
	}

	Popup {
		id: linkPopup
		x: (parent.width - width) / 2
		y: (parent.height - height) / 2

		modal: true
		focus: true
		closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

		property var bridge

		Column {
			anchors.fill: parent
			spacing: 10

			Label { 
				font.bold: true
				text: "Linking with " + (linkPopup.bridge ? linkPopup.bridge.address : "INVALID")
			}

			Label { text: "Press the Link button on the bridge, then click \"Link now\""}
			Row {
				spacing: 10
				anchors.horizontalCenter: parent.horizontalCenter
				Button {
					text: "Link now"
					onClicked: {
						if(linkPopup.bridge)
							linkPopup.bridge.connectToBridge();

						linkPopup.close();
					}
				}
				Button {
					text: "Cancel"
					onClicked: linkPopup.close()
				}
			}
		}
	}
}
