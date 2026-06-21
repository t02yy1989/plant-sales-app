# plant-sales-app

造園業向け植物販売在庫管理アプリ。

## 技術スタック
- フロントエンド: Flutter Web
- バックエンド: FastAPI（Python、非同期）
- DB: MariaDB
- 認証: JWT（ペイロードに role を含む）
- デプロイ: systemd（Linux home server）

## Git運用
- 作業ブランチ: dev
- mainへのマージは動作確認後に手動で行う
- コミットメッセージは日本語でOK

## 関連プロジェクト
- team-todo-scheduler: JWT・DB接続の実装パターンを参考にすること
- 将来的に manage-app と連携予定（現時点は独立）

## バックエンド起動
```bash
cd backend
source venv/bin/activate
uvicorn main:app --reload --port 8001
```

## フロントエンドビルド
```bash
cd frontend
flutter build web
```

## バックエンド構成
- `config.py` : 環境変数・設定
- `database.py`: 非同期SQLAlchemyセッション・Base
- `models.py`  : SQLAlchemyモデル（User, Plant, InventoryLog）
- `schemas.py` : Pydanticスキーマ
- `auth.py`    : JWT生成・検証・ロール依存性注入
- `main.py`    : FastAPIアプリ本体
- `routers/`   : 各エンドポイント

## ロール
- employee: 在庫閲覧・販売入力のみ。purchase_price はAPIから除外
- executive: 仕入れ・マスタ管理・レポート・廃棄
- admin: 上記すべて＋ユーザー管理
