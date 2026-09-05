-- 漫剧创作项目数据库 Schema
-- 版本: 1.0
-- 说明: 使用 SQLite 管理漫剧项目的资产、分镜、剧本等核心数据
-- 用法: sqlite3 projects/<项目名>/<项目名>.db < schema.sql

-- ============================================
-- 项目配置表
-- ============================================
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,              -- 项目名称
    style TEXT NOT NULL,                    -- 艺术风格 (如: 2D_chinese_guofeng)
    total_episodes INTEGER,                 -- 总集数
    episode_duration REAL,                  -- 单集时长(分钟)
    platform TEXT DEFAULT '竖屏',           -- 平台规格
    paywall_strategy TEXT,                  -- 付费策略
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 资产表 (统一管理所有资产)
-- ============================================
CREATE TABLE IF NOT EXISTS assets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    type TEXT NOT NULL,                     -- character/scene/prop
    category TEXT NOT NULL,                 -- 人物/场景/物品
    name TEXT NOT NULL,
    description TEXT,
    file_path TEXT,                         -- 相对路径 (如: 图片资产/人物/主角.png)
    thumbnail_path TEXT,
    width INTEGER,
    height INTEGER,
    format TEXT,                            -- png/jpg/mp4
    status TEXT DEFAULT 'pending',          -- pending/processing/done/error
    generated_url TEXT,                     -- 生成后的URL
    prompt TEXT,                            -- 生成提示词
    metadata JSON,                          -- 扩展元数据
    tags TEXT,                              -- 标签 (逗号分隔)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- ============================================
-- 角色资产扩展表
-- ============================================
CREATE TABLE IF NOT EXISTS characters (
    asset_id INTEGER PRIMARY KEY,
    age INTEGER,
    gender TEXT,
    role TEXT,                              -- 主角/配角/反派/群演
    personality TEXT,                       -- 性格特征
    appearance TEXT,                        -- 外貌描述
    clothing TEXT,                          -- 服装描述
    baseline_prompt TEXT,                   -- 基础提示词
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
);

-- ============================================
-- 场景资产扩展表
-- ============================================
CREATE TABLE IF NOT EXISTS scenes (
    asset_id INTEGER PRIMARY KEY,
    indoor_outdoor TEXT,                    -- indoor/outdoor
    time_of_day TEXT,                       -- 清晨/上午/中午/下午/黄昏/夜晚
    season TEXT,                            -- 春/夏/秋/冬
    key_elements TEXT,                      -- 关键元素 (逗号分隔)
    atmosphere TEXT,                        -- 氛围描述
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE
);

-- ============================================
-- 衍生资产表
-- ============================================
CREATE TABLE IF NOT EXISTS asset_derivatives (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_asset_id INTEGER NOT NULL,
    type TEXT NOT NULL,                     -- 服装变体/时间变体/状态变体
    name TEXT NOT NULL,
    description TEXT,
    file_path TEXT,
    status TEXT DEFAULT 'pending',
    prompt TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_asset_id) REFERENCES assets(id) ON DELETE CASCADE
);

-- ============================================
-- 剧本表
-- ============================================
CREATE TABLE IF NOT EXISTS scripts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    episode_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    synopsis TEXT,                          -- 剧情梗概
    content TEXT,                           -- 完整剧本内容 (XML格式)
    duration_seconds INTEGER,               -- 预计时长(秒)
    word_count INTEGER,                     -- 台词字数
    scene_count INTEGER,                    -- 场景数
    shot_count INTEGER,                     -- 镜头数
    emotional_points TEXT,                  -- 情绪点 (爆点/虐点/爽点)
    hook_line TEXT,                         -- 集末钩子
    status TEXT DEFAULT 'draft',            -- draft/review/final
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- ============================================
-- 分镜表
-- ============================================
CREATE TABLE IF NOT EXISTS storyboards (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    script_id INTEGER,
    episode_number INTEGER NOT NULL,
    scene_number INTEGER,                   -- 场次编号
    segment_number INTEGER,                 -- 片段编号
    sequence INTEGER NOT NULL,              -- 镜头序号
    shot_type TEXT,                         -- 景别: 特写/近景/中景/全景
    camera_move TEXT,                       -- 运镜: 固定/缓推/跟随/摇移
    duration_seconds REAL,                  -- 时长(秒)
    visual_description TEXT,                -- 画面描述
    dialogue TEXT,                          -- 台词
    sound_effect TEXT,                      -- 音效
    vo_text TEXT,                           -- 旁白/内心独白
    character_ids TEXT,                     -- 出场角色ID (逗号分隔)
    asset_ids TEXT,                         -- 引用资产ID (逗号分隔)
    notes TEXT,                             -- 备注
    status TEXT DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (script_id) REFERENCES scripts(id) ON DELETE SET NULL
);

-- ============================================
-- 小说章节表
-- ============================================
CREATE TABLE IF NOT EXISTS novel_chapters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    chapter_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    file_path TEXT,                         -- 原始文件路径
    word_count INTEGER,
    summary TEXT,
    key_events TEXT,                        -- 关键事件 (JSON数组)
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- ============================================
-- 导演规划表
-- ============================================
CREATE TABLE IF NOT EXISTS director_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    script_id INTEGER,
    plan_content TEXT,                      -- 导演规划内容
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (script_id) REFERENCES scripts(id) ON DELETE SET NULL
);

-- ============================================
-- 视频片段表
-- ============================================
CREATE TABLE IF NOT EXISTS video_clips (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    storyboard_id INTEGER,
    episode_number INTEGER NOT NULL,
    sequence INTEGER NOT NULL,
    file_path TEXT,                         -- 生成后的视频文件路径
    thumbnail_path TEXT,
    duration_seconds REAL,
    status TEXT DEFAULT 'pending',          -- pending/processing/done/error
    generated_url TEXT,
    error_message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (storyboard_id) REFERENCES storyboards(id) ON DELETE SET NULL
);

-- ============================================
-- 项目任务记录表
-- ============================================
CREATE TABLE IF NOT EXISTS project_tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_id INTEGER NOT NULL,
    task_type TEXT NOT NULL,                -- skeleton/adaptation/script/storyboard/asset/video
    task_name TEXT NOT NULL,
    status TEXT DEFAULT 'pending',          -- pending/running/completed/failed
    progress REAL DEFAULT 0,                -- 进度 0-100
    started_at DATETIME,
    completed_at DATETIME,
    error_message TEXT,
    output_path TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- ============================================
-- 创建索引优化查询性能
-- ============================================
CREATE INDEX IF NOT EXISTS idx_assets_project ON assets(project_id);
CREATE INDEX IF NOT EXISTS idx_assets_type ON assets(project_id, type);
CREATE INDEX IF NOT EXISTS idx_assets_category ON assets(project_id, category);
CREATE INDEX IF NOT EXISTS idx_assets_status ON assets(status);
CREATE INDEX IF NOT EXISTS idx_assets_file ON assets(file_path);

CREATE INDEX IF NOT EXISTS idx_storyboards_episode ON storyboards(episode_number);
CREATE INDEX IF NOT EXISTS idx_storyboards_script ON storyboards(script_id);
CREATE INDEX IF NOT EXISTS idx_storyboards_scene ON storyboards(scene_number);
CREATE INDEX IF NOT EXISTS idx_storyboards_assets ON storyboards(asset_ids);

CREATE INDEX IF NOT EXISTS idx_scripts_episode ON scripts(project_id, episode_number);
CREATE INDEX IF NOT EXISTS idx_scripts_status ON scripts(status);

CREATE INDEX IF NOT EXISTS idx_video_clips_episode ON video_clips(episode_number);
CREATE INDEX IF NOT EXISTS idx_video_clips_status ON video_clips(status);

CREATE INDEX IF NOT EXISTS idx_novel_chapters_project ON novel_chapters(project_id);
CREATE INDEX IF NOT EXISTS idx_project_tasks_project ON project_tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_project_tasks_type ON project_tasks(task_type);

-- ============================================
-- 创建视图简化常用查询
-- ============================================

-- 资产概览视图
CREATE VIEW IF NOT EXISTS v_asset_summary AS
SELECT 
    a.project_id,
    a.type,
    a.category,
    COUNT(*) as count,
    SUM(CASE WHEN a.status = 'done' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN a.status = 'pending' THEN 1 ELSE 0 END) as pending
FROM assets a
GROUP BY a.project_id, a.type, a.category;

-- 分镜概览视图
CREATE VIEW IF NOT EXISTS v_episode_stats AS
SELECT 
    s.project_id,
    s.episode_number,
    s.title,
    COUNT(sb.id) as total_shots,
    SUM(sb.duration_seconds) as total_duration,
    SUM(CASE WHEN sb.status = 'done' THEN 1 ELSE 0 END) as completed_shots
FROM scripts s
LEFT JOIN storyboards sb ON s.id = sb.script_id
GROUP BY s.id;

-- 资产使用情况视图
CREATE VIEW IF NOT EXISTS v_asset_usage AS
SELECT 
    a.id as asset_id,
    a.name,
    a.type,
    COUNT(sb.id) as usage_count,
    GROUP_CONCAT(DISTINCT sb.episode_number) as episodes_used
FROM assets a
LEFT JOIN storyboards sb ON a.id = CAST(sb.asset_ids AS INTEGER)
GROUP BY a.id;
