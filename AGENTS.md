# Repository guidance

このリポジトリの目的、コンテナ境界、ツール選定基準、更新方針は
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) を参照してください。

変更時は次を守ってください。

- 開発ツールは原則としてDockerビルド時に導入し、初回起動後の追加構築を要求しない。
- 事前ビルド済みバイナリまたはpackage bottleを優先し、重量級toolchainやサービスを安易に追加しない。
- ホストからmountする設定・認証領域と、イメージへ焼き込む実行ファイルを分離する。
- `make clean` はCCCのコンテナとCompose networkをクリーンアップでき、対象リソースが存在しない場合を含めて繰り返し成功する状態にする。
- シェル変更後は `bash -n`、`shellcheck`、`test/host-token-test.sh` を実行する。
