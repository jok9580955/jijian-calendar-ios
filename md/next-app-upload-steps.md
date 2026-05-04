# 下一款 iOS App 开发上传顺序步骤

这份清单用于下一个独立 iOS App：从立项、开发、本地化、截图、上传，到 App Store Connect 准备完成。按顺序执行，避免漏字段、漏语言、漏截图、重复上传无效构建。

## 1. 确定产品和差异点

1. 明确目标用户、付费方式、核心功能、隐私承诺。
2. 只参考竞品的公开功能范围，不复制品牌、图标、截图、UI、文案。
3. 写出首版功能边界：必须做、可延后、明确不做。
4. 确定 App Store 主名称、副标题、关键词方向。

## 2. 建立项目底座

1. 新建 SwiftUI iOS 项目。
2. 设置 `Bundle Identifier`、`Team`、`Deployment Target`。
3. 配置 App 显示名、版本号、构建号。
4. 新增必要 Target，例如 Widget、App Intents、Share Extension。
5. 配置 Signing、Capabilities、Entitlements。
6. 初始化 Git，并创建 `codex/<app-release-branch>` 分支。

## 3. 设计数据模型和核心架构

1. 定义核心模型，例如任务、日程、倒数日、笔记、配置、主题等。
2. 选择本地存储方案，例如 SwiftData、Core Data、文件存储。
3. 如需同步，配置 iCloud/CloudKit 私有库。
4. 建立 Repository、Service、ViewModel 分层。
5. 先做离线可用，再接系统权限和同步能力。

## 4. 完成核心功能页面

1. 首页必须直接进入可用功能，不做空洞营销页。
2. 完成新增、编辑、删除、搜索、筛选、排序。
3. 完成设置页、主题页、权限状态页。
4. 完成异常状态：空数据、权限拒绝、同步失败、无网络。
5. 每个商店截图要展示的功能页，都要有稳定入口。

## 5. 完成增强功能

1. 加入小组件、锁屏小组件、App Shortcuts、通知提醒等差异化能力。
2. 如接入系统数据，例如日历、提醒事项、照片，必须支持权限拒绝后的降级体验。
3. 加入导入导出能力，例如 CSV、ICS、JSON，按产品类型选择。
4. 加入隐私模式：无账号、无广告、无第三方分析优先。

## 6. 准备 App 图标和启动视觉

1. 生成或设计原创 App Icon。
2. 导入完整 `AppIcon.appiconset`。
3. 检查浅色、深色、透明背景、圆角裁切效果。
4. 不使用竞品近似图标、近似颜色组合或近似符号。

## 7. 建立本地化语言范围

1. 确定 App Store locale 列表。
2. 为每个 locale 准备 App 名称、副标题、关键词、描述、宣传文本。
3. 为每个 locale 准备 App 内 `Localizable.xcstrings`。
4. App 名称也必须本地化，不只本地化描述。
5. 重点检查长文本语言：德语、俄语、葡萄牙语、法语。
6. 重点检查 RTL 语言：阿拉伯语、希伯来语。

## 8. 生成 App Store 元数据

1. 创建 `fastlane/metadata/<locale>/`。
2. 每个 locale 至少包含：
   - `name.txt`
   - `subtitle.txt`
   - `keywords.txt`
   - `description.txt`
   - `promotional_text.txt`
   - `privacy_url.txt`
   - `support_url.txt`
3. 控制 Apple 字段限制：
   - 名称最多 30 字符。
   - 副标题最多 30 字符。
   - 关键词最多 100 字符。
   - 宣传文本最多 170 字符。
4. 运行元数据校验脚本。

## 9. 准备隐私和支持页面

1. 新增 `md/privacy.md`。
2. 新增 `md/support.md`。
3. 推送到 GitHub 后，使用公开 GitHub URL 作为 App Store 隐私和支持链接。
4. 确认所有 locale 的 `privacy_url.txt` 和 `support_url.txt` 都非空。
5. 隐私声明和 App Privacy 问卷必须一致。

## 10. 加入截图模式

1. 为 App 增加 screenshot seed data。
2. 使用固定 mock 数据，避免截图内容随机变化。
3. 使用 `UserDefaults` 或 Fastlane snapshot 参数控制截图状态。
4. 每个功能页面都提供可自动导航的截图入口。
5. 截图文字必须走本地化，不要把中文截图复制到其他语言目录。

## 11. 生成每个语言的截图

1. 先做少量 smoke test：中文、英文、日文、阿拉伯语、德语。
2. 检查页面是否真实本地化。
3. 检查文字是否截断、重叠、超出按钮。
4. 检查深色模式、动态字体、iPhone、iPad。
5. 全量生成截图：每个 locale 5 张 iPhone + 5 张 iPad。
6. 统计截图数量，例如 39 语言应为 390 张。

## 12. 本地构建和测试

1. 执行 Debug 构建。
2. 执行 Release 构建。
3. 运行单元测试和 UI smoke test。
4. 检查 Widget、通知、系统权限、iCloud、导入导出。
5. 修复所有编译错误、权限文案缺失、截图崩溃。

## 13. 创建 App Store Connect App 记录

1. 在 App Store Connect 创建新 App。
2. 填写 Bundle ID、SKU、主语言、分类、价格。
3. 确认 App 信息页创建成功。
4. 不要急着提交审核。

## 14. 配置 Fastlane 和 API Key

1. 在 `fastlane/Fastfile` 配置 App Store Connect API Key。
2. `.p8` 文件只放本机，例如 `/Users/<user>/Desktop/AuthKey_<KEY_ID>.p8`。
3. 仓库里只允许保存 key id、issuer id、key path，不保存私钥正文。
4. 确认 `.gitignore` 忽略 `.p8`、`.build/`、临时报告。

## 15. 上传元数据

1. 上传前运行元数据校验。
2. 执行 `fastlane ios upmeta`。
3. 首次上传要准备 App Review 联系人环境变量。
4. 上传后用 App Store Connect API 校验 39 个 locale 字段是否在线存在。
5. 如果 support/privacy URL 缺失，先修 metadata，再重新上传。

## 16. 上传截图

1. 确认截图目录数量正确。
2. 执行 `fastlane ios uppic`。
3. Apple 偶发 500 错误时，先等 Fastlane 重试。
4. 以最终成功日志和 API 截图数量为准。
5. 校验每个 locale 都有 iPhone 和 iPad 截图。

## 17. Archive 并上传二进制

1. 清理旧 archive。
2. 执行 `xcodebuild archive`。
3. 执行 `xcodebuild -exportArchive` 上传。
4. 如果构建号已使用，只递增 `CURRENT_PROJECT_VERSION`。
5. 等待 App Store Connect 处理到 `VALID`。
6. 选择最新 `VALID` build 到当前 App Store 版本。

## 18. 填写 App Store Connect 必要字段

1. 设置版权。
2. 设置内容版权声明。
3. 填写年龄分级问卷。
4. 填写 App Privacy，例如 `Data Not Collected`。
5. 确认隐私政策 URL、支持 URL、截图、构建、价格都完整。
6. 若 Fastlane 无法上传 App Privacy，用网页手动填写。

## 19. 最终发布前检查

1. API 校验 metadata locale 数量。
2. API 校验 app info locale 数量。
3. API 校验截图数量。
4. API 校验 selected build。
5. API 校验 support/privacy URL 缺失项为空。
6. 检查 Git 是否提交、推送。
7. 检查 README、隐私页、支持页是否为公开可访问链接。

## 20. 提交审核

1. 只有在明确决定提交审核时才执行。
2. 再次确认 App Privacy、年龄分级、价格、截图、构建。
3. 填写审核备注。
4. 点击或自动执行 Submit for Review。
5. 记录提交时间、版本号、构建号、分支和 commit。

## 21. 审核后处理

1. 如果被拒，先保存 Apple 原始拒审理由。
2. 按拒审条款分类：元数据、隐私、功能、崩溃、权限、付款。
3. 修复后重新构建或仅更新元数据。
4. 递增构建号后重新上传二进制。
5. 更新本项目工作流，把新踩坑记录进去。
