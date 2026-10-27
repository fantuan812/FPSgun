# 策划交接

本目录两份合同/计划按生产者原字节保留；最终独立报告在 [QA_REPORT](../validation/independent-v9/QA_REPORT.md)，其 `logs/` 相对路径可直接找到交付日志。`producer-hashes.json` 记录三文档 SHA。报告中的绝对 `historical-workspace/...` 是验收环境位置，不要求用户电脑存在该路径。四个独立入口及两个 fixture 原字节复制到 `tests/`；以脚本相对目录加载 fixture，用户可直接复跑。
