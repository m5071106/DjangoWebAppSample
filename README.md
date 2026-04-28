# DjangoWebAppSample

Django (REST API) + Next.js (フロントエンド) の構成による Web アプリサンプルです。

## 技術スタック

| 役割 | 技術 |
|---|---|
| バックエンド | Python 3.13 / Django 6 / Django REST Framework |
| フロントエンド | Node.js 20 / Next.js 16 (App Router) / TypeScript / Tailwind CSS |
| コンテナ | Docker / Docker Compose |
| クラウド | Azure Container Apps |

## ローカル開発

### 前提条件

- Python 3.13+
- Node.js 20+

### バックエンド (Django)

```bash
# 仮想環境の作成と有効化
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

# 依存パッケージのインストール
pip install -r requirements.txt

# DB マイグレーション
python manage.py migrate

# 開発サーバー起動 (http://localhost:8000)
python manage.py runserver
```

### フロントエンド (Next.js)

```bash
cd frontend

# 環境変数ファイルを作成
cp .env.example .env.local

# 依存パッケージのインストール
npm install

# 開発サーバー起動 (http://localhost:3000)
npm run dev
```

ブラウザで http://localhost:3000 を開くと動作確認できます。

## Docker を使ったローカル確認

```bash
# Docker Desktop を起動してから実行
docker compose build
docker compose up
```

- フロントエンド: http://localhost:3000
- バックエンド: http://localhost:8000

## API エンドポイント

| メソッド | URL | 説明 | リクエスト例 |
|---|---|---|---|
| GET | `/api/hello/` | Hello World を返す | — |
| POST | `/api/greet/` | 名前を受け取り挨拶を返す | `{"name": "Alice"}` |

### レスポンス例

```json
// GET /api/hello/
{"message": "Hello World!"}

// POST /api/greet/
{"message": "Hello, Alice!", "name": "Alice"}
```

## Azure Container Apps へのデプロイ

### 前提条件

- [Azure CLI](https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli) インストール済み
- Docker が起動中
- Azure アカウントにログイン済み

```bash
az login
```

### デプロイ実行

```bash
chmod +x deploy/azure-deploy.sh
./deploy/azure-deploy.sh
```

スクリプトが以下を自動で実行します。

1. Azure Container Registry (ACR) の作成
2. Django イメージのビルド & プッシュ
3. Container Apps 環境の作成
4. バックエンドのデプロイ → URL 取得
5. フロントエンドを本番 URL でビルド & デプロイ
6. Django の CORS 設定をフロントエンド URL で更新

### リソースの削除

```bash
az group delete --name hello-world-rg --yes
```

## ディレクトリ構成

```
DjangoWebAppSample/
├── config/               Django プロジェクト設定
├── hello/                Hello World アプリ (views / serializers / urls)
├── frontend/             Next.js プロジェクト
│   └── src/app/
│       ├── page.tsx              GET /api/hello/ 表示ページ
│       └── components/
│           └── GreetForm.tsx     POST /api/greet/ フォーム
├── deploy/
│   └── azure-deploy.sh   Azure 一括デプロイスクリプト
├── Dockerfile            Django 本番イメージ
├── docker-compose.yml    ローカル Docker 確認用
├── entrypoint.sh         migrate → gunicorn 起動
└── requirements.txt      Python 依存パッケージ
```
