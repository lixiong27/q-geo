import pymysql

# 连接参数
conn = pymysql.connect(
    host='10.90.161.88',
    port=3510,
    user='mkt_ares_live',
    password='mkt_ares_live',
    database='mkt_ares_live'
)

try:
    with conn.cursor() as cursor:
        # 执行 ALTER TABLE hot_word
        print('Adding type column to hot_word table...')
        cursor.execute("ALTER TABLE `hot_word` ADD COLUMN `type` VARCHAR(64) DEFAULT NULL COMMENT '热词类型（从QConfig获取）' AFTER `tags`")
        print('Adding index on type column...')
        cursor.execute('ALTER TABLE `hot_word` ADD KEY `idx_type` (`type`)')
        print('Adding model column to hot_word_task table...')
        cursor.execute("ALTER TABLE `hot_word_task` ADD COLUMN `model` VARCHAR(32) NOT NULL DEFAULT 'default' COMMENT '模型标识：default/deepseek/qianwen/doubao等' AFTER `type`")
        conn.commit()
        print('Migration completed successfully!')
except Exception as e:
    print(f'Error: {e}')
    conn.rollback()
finally:
    conn.close()
