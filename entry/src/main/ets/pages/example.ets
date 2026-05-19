/*
    日期：2026/5/19 09:06
    作者：谭锋
*/
import { promptAction } from '@kit.ArkUI'

// ============================================================
// 设备卡片 — 自定义 @Component，实现开关动画与滑块交互
// ============================================================
@Component
struct DeviceCard {
  @Prop name: string = ''
  @Prop icon: string = ''
  @Prop deviceType: string = ''
  @State isOn: boolean = false
  @State briVal: number = 50
  @State temperature: number = 24
  @State tempScale: number = 1

  build() {
    Column() {
      // 设备图标
      Text(this.icon)
        .fontSize(32)
        .opacity(this.isOn ? 1 : 0.5)

      // 设备名称
      Text(this.name)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ top: 8 })

      // ---- 灯光亮度滑块（仅灯光设备 && 开启时显示） ----
      if (this.isOn && this.deviceType === 'light') {
        Row() {
          Text('🔅').fontSize(16).margin({ right: 6 })
          Slider({ min: 0, max: 100, value: this.briVal })
            .width('70%')
            .selectedColor('#FFB800')
            .trackColor('#E8E8E8')
            .onChange((value: number) => {
              this.briVal = value
            })
          Text('🔆').fontSize(16).margin({ left: 6 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })
      }

      // ---- 空调温度滑块（仅空调设备 && 开启时显示） ----
      if (this.isOn && this.deviceType === 'ac') {
        Column() {
          Text(`${this.temperature}°C`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getTempColor())
            .scale({ x: this.tempScale, y: this.tempScale })
            .animation({ duration: 200, curve: Curve.EaseInOut })

          Slider({ min: 16, max: 30, value: this.temperature })
            .width('100%')
            .selectedColor(this.getTempColor())
            .trackColor('#E8E8E8')
            .onChange((value: number) => {
              this.temperature = value
              // 数字跳动动画
              this.tempScale = 1.4
              animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
                this.tempScale = 1
              })
            })
        }
        .width('100%')
        .margin({ top: 8 })
      }

      // 开关状态文字
      Text(this.isOn ? '已开启' : '已关闭')
        .fontSize(11)
        .fontColor(this.isOn ? '#4CAF50' : '#999999')
        .margin({ top: this.isOn && (this.deviceType === 'light' || this.deviceType === 'ac') ? 4 : 10 })
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: 10, right: 10 })
    .borderRadius(10)
    .backgroundColor(this.getCardBg())
    .scale({ x: this.isOn ? 1.02 : 1, y: this.isOn ? 1.02 : 1 })
    .animation({ duration: 300, curve: Curve.EaseInOut })
    .onClick(() => {
      animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
        this.isOn = !this.isOn
      })
    })
  }

  // 根据设备类型与状态返回卡片背景色
  getCardBg(): string {
    if (!this.isOn) {
      return '#F5F5F5'
    }
    if (this.deviceType === 'light') {
      // 亮度越高越接近暖白
      const r = Math.round(245 + 10 * this.briVal / 100)
      const g = Math.round(245 + 4 * this.briVal / 100)
      const b = Math.round(245 - 15 * this.briVal / 100)
      return rgbStr(r, g, b)
    }
    if (this.deviceType === 'ac') {
      return '#F0F5FF'
    }
    // 其他设备开启时淡绿底色
    return '#F0FFF5'
  }

  // 空调温度色值：蓝色(制冷) → 橙色(制热)
  getTempColor(): string {
    const t = (this.temperature - 16) / 14
    const r = Math.round(0 + 255 * t)
    const g = Math.round(122 + 27 * t)
    const b = Math.round(255 * (1 - t))
    return rgbStr(r, g, b)
  }
}

// --- 工具：将 RGB 三值转为 '#rrggbb' 格式 ---
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
// 智能家居首页 — @Entry 主页面
// ============================================================
@Entry
@Component
struct SmartHome {
  @State envTemp: number = 26
  @State envHumidity: number = 55
  @State envLight: number = 800
  @State activeTab: number = 0

  build() {
    Column() {
      // ===================== 顶部: 环境数据栏 =====================
      Row() {
        // 温度
        Column() {
          Text('🌡️').fontSize(26)
          Text('温度').fontSize(11).fontColor('#999999')
          Text(`${this.envTemp}°C`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B35')
        }
        .onClick(() => {
          this.envTemp = 20 + Math.floor(Math.random() * 16)
        })

        Divider().vertical(true).height(40).color('#E8E8E8')

        // 湿度
        Column() {
          Text('💧').fontSize(26)
          Text('湿度').fontSize(11).fontColor('#999999')
          Text(`${this.envHumidity}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4A90D9')
        }
        .onClick(() => {
          this.envHumidity = 30 + Math.floor(Math.random() * 50)
        })

        Divider().vertical(true).height(40).color('#E8E8E8')

        // 光照
        Column() {
          Text('☀️').fontSize(26)
          Text('光照').fontSize(11).fontColor('#999999')
          Text(`${this.envLight}lux`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFB800')
        }
        .onClick(() => {
          this.envLight = 200 + Math.floor(Math.random() * 1200)
        })
      }
      .width('100%')
      .padding({ top: 14, bottom: 14, left: 8, right: 8 })
      .justifyContent(FlexAlign.SpaceAround)
      .backgroundColor('#FFFFFF')

      // ===================== 中间: 设备卡片网格 =====================
      Scroll() {
        Grid() {
          GridItem() {
            DeviceCard({ name: '客厅灯', icon: '💡', deviceType: 'light' })
          }
          GridItem() {
            DeviceCard({ name: '卧室灯', icon: '🛋️', deviceType: 'light' })
          }
          GridItem() {
            DeviceCard({ name: '空调', icon: '❄️', deviceType: 'ac' })
          }
          GridItem() {
            DeviceCard({ name: '热水器', icon: '🔥', deviceType: 'heater' })
          }
          GridItem() {
            DeviceCard({ name: '智能音箱', icon: '🔊', deviceType: 'speaker' })
          }
          GridItem() {
            DeviceCard({ name: '智能窗帘', icon: '🪟', deviceType: 'curtain' })
          }
          GridItem() {
            DeviceCard({ name: '智能门锁', icon: '🔐', deviceType: 'lock' })
          }
          GridItem() {
            DeviceCard({ name: '空气净化器', icon: '🌀', deviceType: 'purifier' })
          }
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .padding(12)
      }
      .layoutWeight(1)
      .backgroundColor('#F0F2F5')
      .scrollBar(BarState.Off)

      // ===================== 底部: TabBar 导航栏 =====================
      Row() {
        // 首页
        Column() {
          Text('🏠').fontSize(22)
          Text('首页')
            .fontSize(12)
            .fontColor(this.activeTab === 0 ? '#4A90D9' : '#999999')
            .fontWeight(this.activeTab === 0 ? FontWeight.Bold : FontWeight.Normal)
        }
        .onClick(() => {
          this.activeTab = 0
        })

        // 场景
        Column() {
          Text('🎬').fontSize(22)
          Text('场景')
            .fontSize(12)
            .fontColor(this.activeTab === 1 ? '#4A90D9' : '#999999')
            .fontWeight(this.activeTab === 1 ? FontWeight.Bold : FontWeight.Normal)
        }
        .onClick(() => {
          this.activeTab = 1
        })

        // 设置
        Column() {
          Text('⚙️').fontSize(22)
          Text('设置')
            .fontSize(12)
            .fontColor(this.activeTab === 2 ? '#4A90D9' : '#999999')
            .fontWeight(this.activeTab === 2 ? FontWeight.Bold : FontWeight.Normal)
        }
        .onClick(() => {
          this.activeTab = 2
        })
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
  }
}