# 资产提取与生成 Skill

## 概述

本 Skill 负责从剧本中提取资产清单，并生成对应的图像生成提示词。

---

## 第一步：资产提取

### 执行流程

1. 读取已生成的剧本文件
2. 分析剧本中的角色、场景、道具
3. 按类型分类并生成资产清单

### 提取规则

| 资产类型 | 提取内容 | 优先级判断 |
|---------|---------|-----------|
| **角色** | 出场人物（外貌、服装、性格特征） | 主角 > 配角 > 群演 |
| **场景** | 出现的地点（环境、光线、氛围） | 主要场景 > 次要场景 |
| **道具** | 重要物品（外观、用途） | 关键道具 > 普通道具 |

### 输出格式

```markdown
## 资产提取报告

### 角色资产 (X 个)
| ID | 名称 | 描述 | 优先级 | 是否需要衍生 |
|----|------|------|--------|-------------|
| C01 | [角色名] | [外貌、服装、性格描述] | 高/中/低 | 否/是 |

### 场景资产 (X 个)
| ID | 名称 | 描述 | 优先级 | 是否需要时间变体 |
|----|------|------|--------|----------------|
| S01 | [场景名] | [环境、光线、氛围描述] | 高/中/低 | 否/是 |

### 道具资产 (X 个)
| ID | 名称 | 描述 | 优先级 |
|----|------|------|--------|
| P01 | [道具名] | [外观、用途描述] | 高/中/低 |
```

---

## 第二步：生成提示词

### 提示词模板（根据艺术风格自动选择）

#### 角色生成提示词

```
[风格前缀]，character design sheet, character turnaround,
[角色外貌描述]，[服装描述]，[发型描述]，[配饰描述]，
同一画面左至右并排：人像特写+正视图+侧视图+后视图，
纯色背景，均匀柔光，无硬阴影，
图中不要有任何文字，no text
```

**风格前缀对照表：**

| 艺术风格 | 前缀 |
|---------|------|
| 2D_chinese_guofeng | 国风二次元，新国潮美学，日式动画渲染，赛璐璐平涂，细腻笔触 |
| 2D_flat_design | 扁平设计风格，简约线条，几何化造型，明快色彩 |
| 3D_anime_render | 3D动漫渲染，stylized 3D character，anime-inspired |
| realpeople_modern_city | 真人质感，现代都市风格，realistic human character |

#### 场景生成提示词

```
[风格前缀]，scene design sheet, environment concept art, no people, no characters,
[场景环境描述]，[光线描述]，[氛围描述]，
柔和光影，[渲染风格]，细腻质感，
图中不要有任何文字，no text
```

#### 道具生成提示词

```
[风格前缀]，prop closeup, detailed object shot, no people,
[道具外观描述]，[材质描述]，
纯色背景，均匀柔光，无硬阴影，
图中不要有任何文字，no text
```

---

## 第三步：衍生资产分析

### 角色衍生（变身状态）

| 衍生类型 | 提取条件 | 示例 |
|---------|---------|------|
| 服装 | 明显换装/变身 | 校服→战斗服、礼服、盔甲 |
| 特效 | 变身光效/能量 | 变身光效、能量缠绕 |
| 变形 | 体型/结构改变 | 兽化、巨大化、异化 |

**衍生提示词模板：**

```
[基础角色提示词]，
[变化描述]，[特效描述]，
保持角色识别度，[状态]氛围
```

### 场景衍生（时间变体）

| 时间变体 | 光照调整 | 色调调整 |
|---------|---------|---------|
| 夜景 | 月光/路灯/室内光 | 冷色调（蓝紫） |
| 黄昏 | 夕阳/暖光 | 暖色调（橙红） |
| 清晨 | 朝阳/柔和光 | 淡色调（粉蓝） |

**衍生提示词模板：**

```
[基础场景提示词]，
[时段描述]，[特殊光照]，[氛围调整]
```

---

## 完整示例

### 输入：剧本片段

```xml
<scene>
  <description>月光下的古老宅院，青石板路，古槐树</description>
  <dialogue character="沈砚辞">（白衣飘飘，手持折扇）这宅子...有些年头了。</dialogue>
</scene>
<scene>
  <description>书房内，烛火摇曳，书架林立</description>
  <dialogue character="小翠">（端着茶盘）公子，茶来了。</dialogue>
</scene>
```

### 输出：资产清单

```markdown
## 资产提取报告

### 角色资产
| ID | 名称 | 描述 | 优先级 | 衍生 |
|----|------|------|--------|------|
| C01 | 沈砚辞 | 儒雅青年，黑色长发束起，白衣长衫，手持折扇，气质清冷 | 高 | 否 |
| C02 | 小翠 | 丫鬟装扮，青色衣裙，发髻简单，端庄温婉 | 中 | 否 |

### 场景资产
| ID | 名称 | 描述 | 优先级 | 衍生 |
|----|------|------|--------|------|
| S01 | 古宅外景 | 月光下的古老宅院，青石板路，古槐树，幽静神秘 | 高 | 是（夜景） |
| S02 | 书房内景 | 烛火摇曳，书架林立，古色古香 | 高 | 否 |

### 道具资产
| ID | 名称 | 描述 | 优先级 |
|----|------|------|--------|
| P01 | 折扇 | 白色扇面，黑色扇骨，文人雅致 | 中 |
| P02 | 茶盘 | 木质茶盘，茶具齐全 | 低 |
```

### 输出：生成提示词

**C01 沈砚辞：**
```
国风二次元，新国潮美学，日式动画渲染，赛璐璐平涂，细腻笔触，
character design sheet, character turnaround,
儒雅青年男性，黑色长发束起，白衣长衫，手持折扇，气质清冷，
同一画面左至右并排：人像特写+正视图+侧视图+后视图，
月白纯色背景，均匀柔光，无硬阴影，
图中不要有任何文字
```

**S01 古宅外景：**
```
国风二次元场景主视图概念图，
国风二次元，新国潮美学，日式动画渲染，赛璐璐平涂，细腻笔触，
Japanese anime style, cel shading, fine brushstrokes，
scene design sheet, environment concept art, no people, no characters，
月光下的古老宅院，青石板路，古槐树，幽静神秘氛围，
柔和光影，日式渲染，自然光漫射，细腻质感，
图中不要有任何文字
```

---

## 工具函数

### PowerShell 辅助函数

```powershell
# 生成角色提示词
function New-CharacterPrompt {
    param($CharacterName, $Description, $Style)
    
    $prefix = Get-StylePrefix -Style $Style
    return @"
$prefix，character design sheet, character turnaround,
$Description，
同一画面左至右并排：人像特写+正视图+侧视图+后视图，
纯色背景，均匀柔光，无硬阴影，
图中不要有任何文字，no text
"@
}

# 生成场景提示词
function New-ScenePrompt {
    param($SceneName, $Description, $Style)
    
    $prefix = Get-StylePrefix -Style $Style
    return @"
$prefix，scene design sheet, environment concept art, no people, no characters,
$Description，
柔和光影，日式渲染，细腻质感，
图中不要有任何文字，no text
"@
}

# 获取风格前缀
function Get-StylePrefix {
    param($Style)
    
    switch ($Style) {
        "2D_chinese_guofeng" { return "国风二次元，新国潮美学，日式动画渲染，赛璐璐平涂，细腻笔触" }
        "2D_flat_design" { return "扁平设计风格，简约线条，几何化造型，明快色彩" }
        "3D_anime_render" { return "3D动漫渲染，stylized 3D character，anime-inspired" }
        "realpeople_modern_city" { return "真人质感，现代都市风格，realistic human character" }
        default { return "anime style, detailed illustration" }
    }
}
```

---

## 相关 Skill

- `production_execution_derive_assets.md` - 衍生资产分析
- `production_execution_generate_assets.md` - 资产图片生成
- `art_styles/*/README.md` - 各风格提示词模板
