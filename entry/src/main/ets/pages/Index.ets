/*
   SmartHome App — SMART-R 开发板智能家居主页面
   日期：2026/5/19
   作者：谭锋

   硬件平台: 通晓SMART-R (瑞芯微RK2206)
   支持: ADC / PWM / I2C / SPI / UART / WiFi 2.4G
   板载: RGB灯、直流电机、温湿度传感器、加速度传感器
*/

import { promptAction } from '@kit.ArkUI'

// ============================================================
// 工具函数 — RGB 色彩转换
// ============================================================
function rgbStr(r: number, g: number, b: number): string {
  const num = (clamp(r) * 256 + clamp(g)) * 256 + clamp(b)
  let hex = num.toString(16)
  const pad = '000000'
  hex = pad.substring(0, pad.length - hex.length) + hex
  return '#' + hex
}

function clamp(v: number): number {
  if (v < 0) return 0
  if (v > 255) return 255
  return v
}


// ============================================================
// DeviceCard — 通用设备控制卡片
// ============================================================
@Component
struct DeviceCard {
  @Prop name: string = ''
  @Prop icon: string = ''
  @Prop deviceType: string = ''
  @State isOn: boolean = false
  @State sliderValue: number = 50

  build() {
    Column() {
      Text(this.icon)
        .fontSize(32)
        .opacity(this.isOn ? 1 : 0.5)

      Text(this.name)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ top: 8 })

      // 灯光: 亮度滑块
      if (this.isOn && this.deviceType === 'rgb_light') {
        Row() {
          Text('🔅').fontSize(16).margin({ right: 6 })
          Slider({ min: 0, max: 100, value: this.sliderValue })
            .width('70%')
            .selectedColor('#FFB800')
            .trackColor('#E8E8E8')
            .onChange((value: number) => {
              this.sliderValue = value
            })
          Text('🔆').fontSize(16).margin({ left: 6 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })
      }

      // 风扇: 风速滑块
      if (this.isOn && this.deviceType === 'fan') {
        Column() {
          Text(`风速 ${this.sliderValue}`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4A90D9')
            .margin({ bottom: 4 })

          Slider({ min: 0, max: 100, value: this.sliderValue })
            .width('100%')
            .selectedColor('#4A90D9')
            .trackColor('#E8E8E8')
            .onChange((value: number) => {
              this.sliderValue = value
            })
        }
        .width('100%')
        .margin({ top: 8 })
      }

      Text(this.isOn ? '已开启' : '已关闭')
        .fontSize(11)
        .fontColor(this.isOn ? '#4CAF50' : '#999999')
        .margin({ top: this.isOn ? 4 : 10 })
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: 10, right: 10 })
    .borderRadius(10)
    .backgroundColor(this.isOn ? this.getActiveBg() : '#F5F5F5')
    .scale({ x: this.isOn ? 1.02 : 1, y: this.isOn ? 1.02 : 1 })
    .animation({ duration: 300, curve: Curve.EaseInOut })
    .onClick(() => {
      animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
        this.isOn = !this.isOn
      })
    })
  }

  getActiveBg(): string {
    if (this.deviceType === 'rgb_light') {
      const r = Math.round(245 + 10 * this.sliderValue / 100)
      const g = Math.round(245 + 4 * this.sliderValue / 100)
      const b = Math.round(245 - 15 * this.sliderValue / 100)
      return rgbStr(r, g, b)
    }
    return '#F0FFF5'
  }
}


// ============================================================
// EnvTile — 环境数据模块
// ============================================================
@Component
struct EnvTile {
  @Prop label: string = ''
  @Prop icon: string = ''
  @Prop value: string = ''
  @Prop valueColor: string = '#333333'
  @Prop unit: string = ''

  build() {
    Column() {
      Text(this.icon).fontSize(26)
      Text(this.label).fontSize(11).fontColor('#999999')
      Text(`${this.value}${this.unit}`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.valueColor)
    }
  }
}


// ============================================================
// SmartHome 主页面 — @Entry
// ============================================================
@Entry
@Component
struct SmartHome {
  @State envTemp: number = 26
  @State envHumidity: number = 55
  @State boardVoltage: number = 3.3
  @State wifiSSID: string = 'SMART-R'
  @State showWifiPopup: boolean = false
  @State wifiInput: string = ''
  @State activeTab: number = 0

  // 模拟从开发板获取传感器数据 (后续接入 SDK 替换)
  refreshSensorData() {
    this.envTemp = 20 + Math.floor(Math.random() * 16)
    this.envHumidity = 30 + Math.floor(Math.random() * 50)
    this.boardVoltage = Math.round((3.1 + Math.random() * 0.5) * 10) / 10
  }

  build() {
    Stack() {
      Column() {
        // ===================== 顶部标题栏 =====================
        Row() {
          Text('🏠 SMART-R 智能家居')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          Blank()

          // WiFi 连接按钮
          Button() {
            Text(this.wifiSSID === '未连接' ? '📡' : '📶')
              .fontSize(18)
          }
          .width(36)
          .height(36)
          .borderRadius(18)
          .backgroundColor('#FFFFFF30')
          .onClick(() => {
            this.showWifiPopup = true
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#2C3E50')

        // ===================== 环境数据栏 =====================
        Row() {
          EnvTile({ label: '温度', icon: '🌡️', value: this.envTemp.toString(), valueColor: '#FF6B35', unit: '°C' })
          Divider().vertical(true).height(40).color('#E8E8E8')
          EnvTile({ label: '湿度', icon: '💧', value: this.envHumidity.toString(), valueColor: '#4A90D9', unit: '%' })
          Divider().vertical(true).height(40).color('#E8E8E8')
          EnvTile({ label: '电压', icon: '⚡', value: this.boardVoltage.toString(), valueColor: '#27AE60', unit: 'V' })
        }
        .width('100%')
        .padding({ top: 14, bottom: 14, left: 8, right: 8 })
        .justifyContent(FlexAlign.SpaceAround)
        .backgroundColor('#FFFFFF')
        .onClick(() => {
          this.refreshSensorData()
        })

        // ===================== 设备控制卡片网格 =====================
        Scroll() {
          Column() {
            // ---- 区段标题: 灯光控制 ----
            Row() {
              Text('💡 灯光控制')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#666666')
            }
            .width('100%')
            .padding({ left: 4, top: 4 })
            .margin({ top: 8 })

            Grid() {
              GridItem() {
                DeviceCard({ name: 'RGB 灯带', icon: '🌈', deviceType: 'rgb_light' })
              }
              GridItem() {
                DeviceCard({ name: '氛围灯', icon: '✨', deviceType: 'rgb_light' })
              }
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)

            // ---- 区段标题: 电机 / 风扇 ----
            Row() {
              Text('🔧 电机控制')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#666666')
            }
            .width('100%')
            .padding({ left: 4, top: 4 })
            .margin({ top: 16 })

            Grid() {
              GridItem() {
                DeviceCard({ name: '直流风扇', icon: '🌀', deviceType: 'fan' })
              }
              GridItem() {
                DeviceCard({ name: '步进电机', icon: '⚙️', deviceType: 'motor' })
              }
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)

            // ---- 区段标题: 传感器数据 ----
            Row() {
              Text('📊 板载传感器')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#666666')
            }
            .width('100%')
            .padding({ left: 4, top: 4 })
            .margin({ top: 16 })

            // 传感器只读展示卡片
            Row() {
              Column() {
                Text('📳').fontSize(28)
                Text('加速度传感器').fontSize(12).fontColor('#999999')
                Text('x:0 y:0 z:9.8').fontSize(13).fontColor('#333333').margin({ top: 4 })
              }
              .width('48%')
              .padding(14)
              .borderRadius(10)
              .backgroundColor('#F8F9FC')

              Column() {
                Text('🌡️').fontSize(28)
                Text('温湿度传感器').fontSize(12).fontColor('#999999')
                Text('DHT11 / AHT20').fontSize(13).fontColor('#333333').margin({ top: 4 })
              }
              .width('48%')
              .padding(14)
              .borderRadius(10)
              .backgroundColor('#F8F9FC')
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 8 })

            // 底部留白让 Scroll 不被 TabBar 遮挡
            Blank().height(16)
          }
          .padding({ left: 12, right: 12 })
        }
        .layoutWeight(1)
        .backgroundColor('#F0F2F5')
        .scrollBar(BarState.Off)

        // ===================== 底部 TabBar 导航栏 =====================
        Row() {
          Column() {
            Text('🏠').fontSize(22)
            Text('首页')
              .fontSize(12)
              .fontColor(this.activeTab === 0 ? '#4A90D9' : '#999999')
              .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
          }
          .onClick(() => { this.activeTab = 0 })

          Column() {
            Text('🎬').fontSize(22)
            Text('场景')
              .fontSize(12)
              .fontColor(this.activeTab === 1 ? '#4A90D9' : '#999999')
              .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
          }
          .onClick(() => { this.activeTab = 1 })

          Column() {
            Text('⚙️').fontSize(22)
            Text('设置')
              .fontSize(12)
              .fontColor(this.activeTab === 2 ? '#4A90D9' : '#999999')
              .fontWeight(this.activeTab === 2 ? FontWeight.Bold : FontWeight.Normal)
          }
          .onClick(() => { this.activeTab = 2 })
        }
        .width('100%')
        .height(60)
        .padding({ left: 8, right: 8 })
        .justifyContent(FlexAlign.SpaceAround)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: -2 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F0F2F5')

      // ===================== WiFi 连接弹窗 =====================
      if (this.showWifiPopup) {
        Column() {
          Column() {
            Text('WiFi 连接')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })

            TextInput({ placeholder: '请输入 WiFi SSID' })
              .width('100%')
              .margin({ bottom: 8 })
              .onChange((value: string) => {
                this.wifiInput = value
              })

            TextInput({ placeholder: '密码 (可选)' })
              .width('100%')
              .type(InputType.Password)
              .margin({ bottom: 16 })

            Row() {
              Button('取消')
                .width('45%')
                .backgroundColor('#CCCCCC')
                .onClick(() => { this.showWifiPopup = false })

              Button('连接')
                .width('45%')
                .backgroundColor('#4A90D9')
                .onClick(() => {
                  if (this.wifiInput.length > 0) {
                    this.wifiSSID = this.wifiInput
                  }
                  this.showWifiPopup = false
                  promptAction.showToast({ message: `正在连接 ${this.wifiInput}...`, duration: 2000 })
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('80%')
          .padding(20)
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#60000000')
        .onClick(() => { this.showWifiPopup = false })
      }
    }
    .width('100%')
    .height('100%')
  }
}
