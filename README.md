# SMART-R 智能家居 App — 项目详细说明

> 作者：谭锋  
> 日期：2026/5/19  
> 项目路径：`d:\SmartHomeApp`  
> 仓库地址：https://github.com/tanfinn/SmartHomeApp.git

---

## 1. 项目概述

这是一个基于**鸿蒙 (HarmonyOS)** 的智能家居控制 App，底层开发环境是 **DevEco Studio**。

**核心目标**：通过手机 App 控制**通晓 SMART-R 开发板**（基于瑞芯微 RK2206 芯片的鸿蒙 IoT 开发板），实现灯光、电机、环境传感器等设备的远程监控。

**目标硬件平台**：

- 芯片：瑞芯微 RK2206
- 接口：ADC / PWM / I2C / SPI / UART
- 无线：WiFi 2.4G，支持 IEEE 802.11 b/g/n，兼容 STA/AP 模式
- 板载外设：RGB 灯、直流电机、温湿度传感器、加速度传感器

---

## 2. 项目目录结构

```
SmartHomeApp/
├── AppScope/                        # 应用级配置（图标、应用名、bundleName）
│   ├── app.json5                    #   包名、版本号、图标/标签引用
│   └── resources/base/media/        #   桌面图标资源（foreground.png 等）
│
├── entry/                           # 主模块（entry 类型）
│   └── src/main/
│       ├── ets/                     # ↑ ArkTS 源代码（核心）
│       │   ├── common/
│       │   │   └── utils.ets        #     工具函数：RGB 颜色转换
│       │   ├── components/
│       │   │   ├── DeviceCard.ets   #     设备控制卡片组件
│       │   │   └── EnvTile.ets      #     环境数据展示组件
│       │   ├── entryability/
│       │   │   └── EntryAbility.ets #     应用入口（UIAbility）
│       │   ├── entrybackupability/
│       │   │   └── EntryBackupAbility.ets  # 备份扩展
│       │   └── pages/
│       │       └── Index.ets        #     @Entry 主页面
│       ├── resources/               # 模块级资源
│       │   └── base/profile/
│       │       └── main_pages.json  #     页面路由注册表
│       └── module.json5             # 模块清单（Ability 声明）
│
├── build-profile.json5              # 工程级构建配置（SDK 版本、签名等）
├── hvigorfile.ts                    # hvigor 构建脚本
└── oh-package.json5                 # 依赖声明
```

---

## 3. 配置文件说明

### 3.1 `build-profile.json5` — 工程构建配置

```json5
{
  "app": {
    "products": [{
      "name": "default",
      "targetSdkVersion": "5.1.1(19)",       // 目标 SDK 版本
      "compatibleSdkVersion": "5.1.1(19)",    // 兼容的最低 SDK 版本
      "runtimeOS": "HarmonyOS"
    }]
  }
}
```

这两个版本号**必须与目标设备的系统版本匹配**，否则运行时会报错 `compatibleSdkVersion and releaseType do not match`。

### 3.2 `AppScope/app.json5` — 应用级清单

```json5
{
  "app": {
    "bundleName": "com.tf.myapplication",   // 应用包名（唯一标识）
    "versionCode": 1000000,                  // 版本号（整数）
    "versionName": "1.0.0",                  // 版本名（展示用）
    "icon": "$media:layered_image",          // 桌面图标（分层图标）
    "label": "$string:app_name"              // 应用名称
  }
}
```

**`$media:layered_image`** 引用 `media/layered_image.json`，该文件定义图标的**前景**和**背景**两层。AppScope 的图标决定了桌面显示的图标。

### 3.3 `entry/src/main/module.json5` — 模块清单

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",                  // 模块类型：entry（主模块）
    "mainElement": "EntryAbility",    // 入口 Ability 名
    "pages": "$profile:main_pages",   // 页面路由表引用
    "abilities": [{                   // Ability 声明
      "name": "EntryAbility",
      "srcEntry": "./ets/entryability/EntryAbility.ets",  // Ability 源码
      "exported": true,
      "skills": [{
        "entities": ["entity.system.home"],
        "actions": ["ohos.want.action.home"]  // 标记为 Home 入口
      }]
    }]
  }
}
```

其中 `"pages": "$profile:main_pages"` 会去 `resources/base/profile/main_pages.json` 读取页面注册表。

### 3.4 `main_pages.json` — 页面路由注册

```json
{
  "src": ["pages/Index"]
}
```

数组中每个元素是一个页面路径（省略 `.ets` 后缀）。**只有在此注册的页面才能被 `router.pushUrl()` 跳转到**，也才能用 `@Entry` 装饰器作为应用入口。

**当前只注册了 `pages/Index`**，所以 `EntryAbility` 加载 `pages/Index` 时会渲染 SmartHome 组件。

---

## 4. 源代码说明

### 4.1 `common/utils.ets` — 工具函数

**导出函数**：

| 函数              | 参数              | 返回值   | 说明                                         |
| ----------------- | ----------------- | -------- | -------------------------------------------- |
| `clamp(v)`        | `v: number`       | `number` | 将数值钳制在 0-255 之间                      |
| `rgbStr(r, g, b)` | `r, g, b: number` | `string` | 将 RGB 三值转为 `#rrggbb` 十六进制颜色字符串 |

**`rgbStr` 实现原理**：

```
(r * 256 + g) * 256 + b  ->  十进制整数  ->  十六进制字符串  ->  #前缀
```

例：`rgbStr(255, 128, 0)` -> `"#ff8000"`（橙色）。

这两个函数是纯逻辑函数，不涉及 UI，所以放在 `common/` 目录下。

---

### 4.2 `components/EnvTile.ets` — 环境数据展示组件

```typescript
@Component
export struct EnvTile {
  @Prop label: string      // 标签文字，如 "温度"
  @Prop icon: string       // 图标 emoji，如 "🌡️"
  @Prop value: string      // 数据值（字符串），如 "26"
  @Prop valueColor: string // 数据文字颜色，如 "#FF6B35"（暖橙）
  @Prop unit: string       // 单位，如 "°C"
}
```

**渲染结果**：垂直排列的图标 + 标签 + 数值（含单位）三行文本。

**`@Prop` 的含义**：属性装饰器，从父组件接收值，子组件不能修改（单向数据流）。

例如父组件调用：

```typescript
EnvTile({ label: '温度', icon: '🌡️', value: '26', valueColor: '#FF6B35', unit: '°C' })
```

---

### 4.3 `components/DeviceCard.ets` — 设备控制卡片（核心组件）

```typescript
import { rgbStr } from '../common/utils'

@Component
export struct DeviceCard {
  @Prop name: string          // 设备名称，如 "RGB 灯带"
  @Prop icon: string          // 设备图标 emoji
  @Prop deviceType: string    // 设备类型："rgb_light" | "fan" | "motor"
  @State isOn: boolean        // 开关状态（内部状态）
  @State sliderValue: number  // 滑块值 0-100（内部状态）
}
```

**交互逻辑**：

1. **点击卡片** -> 切换开关状态 (`isOn`)，带缩放入场动画（1 ~> 1.02 比例）
2. **关闭时**：卡片显示为灰色 `#F5F5F5`，图标半透明
3. **开启时**：
   - 如果是灯光设备（`rgb_light`）：卡片背景随亮度从冷白渐变到暖黄，同时展开**亮度滑块**
   - 如果是风扇设备（`fan`）：展开**风速滑块**
   - 其他设备（如 `motor`）：只显示淡绿背景

**`@State` vs `@Prop`**：

- `@Prop` -> 从父组件传入，子组件只读
- `@State` -> 组件内部私有状态，修改时触发 UI 重渲染

**滑块透传**：使用 `DeviceCard` 的地方只需传 `name`、`icon`、`deviceType`，卡片内部自己管理开关和滑块状态。后续接入硬件 SDK 时，在 `onChange` 回调中添加 GPIO/PWM 控制逻辑即可。

---

### 4.4 `entryability/EntryAbility.ets` — 应用入口

```typescript
export default class EntryAbility extends UIAbility {
  // 创建时：设置颜色模式
  onCreate() { ... }
  
  // 窗口创建时：加载主页面
  onWindowStageCreate(windowStage) {
    windowStage.loadContent('pages/Index', callback)
    //                    ^ 这里的路径对应 main_pages.json 中注册的页面
  }
}
```

**生命周期**（HarmonyOS 的 Ability 生命周期）：

| 回调                   | 触发时机                   |
| ---------------------- | -------------------------- |
| `onCreate`             | Ability 被创建             |
| `onWindowStageCreate`  | 窗口创建完毕，加载 UI 内容 |
| `onWindowStageDestroy` | 窗口销毁                   |
| `onForeground`         | App 切换到前台             |
| `onBackground`         | App 切换到后台             |
| `onDestroy`            | Ability 被销毁             |

当前 `onWindowStageCreate` 中 `loadContent('pages/Index')` 会加载 `pages/Index.ets` 中带有 `@Entry` 装饰器的组件（即 `SmartHome`）。

---

### 4.5 `pages/Index.ets` — 主页面（@Entry）

```typescript
import { promptAction } from '@kit.ArkUI'    // 系统 Toast 提示
import { DeviceCard } from '../components/DeviceCard'
import { EnvTile } from '../components/EnvTile'

@Entry          // <- 标记为应用入口页面
@Component      // <- 声明为 UI 组件
struct SmartHome { ... }
```

#### 4.5.1 状态变量

| 变量            | 类型             | 初始值      | 用途                 |
| --------------- | ---------------- | ----------- | -------------------- |
| `envTemp`       | `@State number`  | `26`        | 模拟温度值（°C）     |
| `envHumidity`   | `@State number`  | `55`        | 模拟湿度值（%）      |
| `boardVoltage`  | `@State number`  | `3.3`       | 模拟板载电压（V）    |
| `wifiSSID`      | `@State string`  | `'SMART-R'` | 当前连接的 WiFi 名称 |
| `showWifiPopup` | `@State boolean` | `false`     | WiFi 弹窗显示/隐藏   |
| `wifiInput`     | `@State string`  | `''`        | 用户输入的 SSID      |
| `activeTab`     | `@State number`  | `0`         | 底部导航栏选中索引   |

#### 4.5.2 整体布局（三层结构）

```
+-----------------------------------+
|  Stack（根容器，支持层叠）          |
|  +-----------------------------+  |
|  | Column（垂直排列）            |  |
|  | +- 顶部标题栏 --------------+  |  |
|  | | "SMART-R 智能家居" WiFi按钮 |  |
|  | +---------------------------+  |  |
|  | +- 环境数据栏 --------------+  |  |
|  | |  温度  |   湿度  |   电压  |  |  |
|  | +---------------------------+  |  |
|  | +- Scroll(可滚动区) --------+  |  |
|  | | 💡 灯光控制               |  |  |
|  | | [RGB灯带] [氛围灯]        |  |  |
|  | | 🔧 电机控制               |  |  |
|  | | [直流风扇] [步进电机]      |  |  |
|  | | 📊 板载传感器             |  |  |
|  | | [加速度] [温湿度]          |  |  |
|  | +---------------------------+  |  |
|  | +- TabBar -----------------+  |  |
|  | |  首页  |  场景  |  设置   |  |  |
|  | +---------------------------+  |  |
|  +-----------------------------+  |  |
|  +- WiFi 弹窗（条件渲染）------+  |  |
|  | 半透明遮罩 + 白色输入框面板  |  |  |
|  +-----------------------------+  |  |
+-----------------------------------+
```

#### 4.5.3 各区域详细说明

**顶部标题栏**（Row 横向布局）：

- 左侧：标题文字 "SMART-R 智能家居"
- 右侧：WiFi 按钮（圆形），点击弹出弹窗
- `Blank()` 是弹性占位符，把两端推到两侧

**环境数据栏**（Row 横向布局）：

- 三个 `EnvTile` 组件横向排列，用 `Divider`（竖线）分隔
- 点击整行触发 `refreshSensorData()`，用随机数模拟传感器刷新
- `justifyContent(FlexAlign.SpaceAround)` 实现均匀分布

**设备控制区**（Scroll 纵向滚动）：

- 内部分为三个区段，各有标题行
- 每段使用 `Grid` + `columnsTemplate('1fr 1fr')` 实现两列卡片布局
- 灯光区：`DeviceCard({ deviceType: 'rgb_light' })`
- 电机区：`DeviceCard({ deviceType: 'fan' })` 和 `'motor'`
- 传感器区：用普通的 `Column` + `Row` 手写只读展示卡片（不是 DeviceCard）

**底部 TabBar**（Row 横向布局）：

- 三个 Tab，使用 `Column` 垂直排列 emoji + 文字
- `activeTab` 状态控制当前选中项的高亮（蓝色文字 + 加粗）
- 点击切换 `activeTab` 值
- `shadow` 添加顶部阴影增强层次感

**WiFi 弹窗**（条件渲染 `if (this.showWifiPopup)`）：

- 最外层是半透明黑色遮罩 `#60000000`，点击遮罩关闭
- 内层是白色圆角面板，包含 SSID 输入框、密码输入框、取消/连接按钮
- 连接成功后更新 `wifiSSID` 并弹出 Toast 提示
- 使用 `Stack`（堆叠布局）把弹窗层叠在主界面之上

#### 4.5.4 数据模拟

```typescript
refreshSensorData() {
  this.envTemp = 20 + Math.floor(Math.random() * 16)       // 20~35°C
  this.envHumidity = 30 + Math.floor(Math.random() * 50)   // 30~79%
  this.boardVoltage = Math.round((3.1 + Math.random() * 0.5) * 10) / 10  // 3.1~3.6V
}
```

**后续接入真实 SDK 时**，只需将此方法中的随机数逻辑替换为开发板的 I2C/ADC 读数即可。

---

## 5. 鸿蒙 ArkTS 关键概念速查

### 5.1 装饰器

| 装饰器       | 含义                                     | 使用场景                                            |
| ------------ | ---------------------------------------- | --------------------------------------------------- |
| `@Entry`     | 标记为页面入口                           | 必须是 `pages/` 下已在 `main_pages.json` 注册的文件 |
| `@Component` | 声明为可复用 UI 组件                     | 每个自定义组件都必须有这个                          |
| `@State`     | 组件内部响应式状态，变化时触发 UI 重渲染 | 组件自身的可变数据                                  |
| `@Prop`      | 从父组件接收的单向属性                   | 子组件接收外部数据，不可修改                        |
| `@Link`      | 从父组件接收的双向绑定（本项目中未使用） | 子组件需要修改父组件数据时                          |

### 5.2 布局容器

| 容器                | 方向        | 说明                                      |
| ------------------- | ----------- | ----------------------------------------- |
| `Column`            | 垂直        | 子元素从上到下排列                        |
| `Row`               | 水平        | 子元素从左到右排列                        |
| `Stack`             | 层叠（Z轴） | 子元素互相堆叠，后写的在上面              |
| `Grid` / `GridItem` | 网格        | 多行多列，通过 `columnsTemplate` 控制列数 |
| `Scroll`            | 滚动        | 内容超出屏幕时可滚动                      |

### 5.3 常用属性方法（链式调用）

```typescript
Text('文字')
  .fontSize(16)                    // 字号
  .fontWeight(FontWeight.Bold)     // 字重
  .fontColor('#333333')            // 颜色
  .opacity(0.5)                    // 透明度（0=全透明，1=不透明）
  .margin({ top: 8 })              // 外边距
  .padding({ left: 10 })           // 内边距
  .borderRadius(10)                // 圆角
  .backgroundColor('#FFFFFF')      // 背景色
  .onClick(() => { ... })          // 点击事件
```

### 5.4 动画

```typescript
// 显式动画：animateTo 包裹状态修改
animateTo({ duration: 300, curve: Curve.EaseInOut }, () => {
  this.isOn = !this.isOn
})

// 属性动画：scale 变化 + animation 过渡
.scale({ x: this.isOn ? 1.02 : 1 })
.animation({ duration: 300, curve: Curve.EaseInOut })
```

---

## 6. 后续开发指南

### 6.1 接入 SMART-R 开发板 SDK

1. 在 `DeviceCard.ets` 的 `onClick` 和 `Slider.onChange` 回调中添加实际的 GPIO/PWM 控制调用
2. 在 `Index.ets` 的 `refreshSensorData()` 中替换为 I2C/ADC 传感器读取
3. WiFi 连接弹窗需要对接开发板的 WiFi STA 模式 AT 指令或 SDK API

### 6.2 添加新设备类型

1. 在 `DeviceCard.ets` 的 `build()` 中添加新的 `if (this.deviceType === 'xxx')` 条件分支
2. 在 `getActiveBg()` 中添加对应的背景色逻辑
3. 在 `Index.ets` 的对应区段添加 `GridItem() { DeviceCard(...) }`

### 6.3 SDK 版本不匹配问题

如果运行报 `compatibleSdkVersion and releaseType do not match`：

- 确认目标设备的 HarmonyOS/OpenHarmony 系统版本
- 修改 `build-profile.json5` 中的 `compatibleSdkVersion` 和 `targetSdkVersion` 为设备对应的版本号

---

## 7. 文件依赖关系图

```
pages/Index.ets (@Entry)
├── import { DeviceCard } from '../components/DeviceCard'
│       └── import { rgbStr } from '../common/utils'
└── import { EnvTile } from '../components/EnvTile'

entryability/EntryAbility.ets
└── 加载 "pages/Index" -> 渲染 SmartHome 组件

main_pages.json
└── 注册 "pages/Index" 为可用页面路由
```

---

## 8. 注意事项

- **不要删除 `.gitignore` 中已忽略的文件路径**：`local.properties`、`.hvigor`、`node_modules`、`oh_modules`、`build` 产物等不应提交到 git
- **图标替换**：将新图标覆盖 `AppScope/resources/base/media/foreground.png` 和 `entry/src/main/resources/base/media/startIcon.png` 即可
- **模块导入路径**：`../components/DeviceCard` 相对于当前文件所在目录，不需要 `.ets` 后缀
