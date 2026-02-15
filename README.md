# remote-develop-env

Google Cloud Compute Engine 上にリモート開発用の VM を構築し、Tailscale 経由で安全に接続するための Terraform 構成です。

スマートフォンのテザリングなど、どこからでも Tailscale ネットワークを通じて開発環境に SSH 接続できます。

## 構成概要

```
┌─────────────┐    Tailscale     ┌──────────────────────────┐
│  ローカル PC  │◄──────────────►│  GCE VM (dev-vm)         │
│  / スマホ    │   (暗号化VPN)   │  - Ubuntu 22.04 LTS      │
└─────────────┘                  │  - Tailscale (subnet router) │
                                 │  - 開発ツール一式          │
                                 └────────┬─────────────────┘
                                          │
                           ┌──────────────┴──────────────┐
                           │  Google Cloud                │
                           │  - VPC (外部IPなし)          │
                           │  - Cloud NAT (外部通信用)    │
                           │  - Cloud DNS (内部名前解決)  │
                           │  - IAP SSH (フォールバック)   │
                           └─────────────────────────────┘
```

## 主な特徴

- **外部IPなし** — VM に外部 IP を付与せず、Cloud NAT 経由で外部通信。攻撃面を最小化
- **Tailscale 接続** — WireGuard ベースの VPN で暗号化されたP2P接続
- **サブネットルーティング** — Tailscale 経由で VPC 内部リソースにアクセス可能
- **IAP SSH フォールバック** — Tailscale に問題がある場合は Identity-Aware Proxy 経由で SSH 接続
- **Shielded VM** — セキュアブート、vTPM、整合性モニタリングを有効化
- **自動セキュリティ更新** — unattended-upgrades による自動パッチ適用

## 前提条件

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (`gcloud`)
- GCP プロジェクト（課金有効化済み）
- [Tailscale アカウント](https://tailscale.com/)

## セットアップ

### 1. GCP 認証

```bash
gcloud auth application-default login
```

### 2. Tailscale Auth Key の取得

[Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys) で Auth Key を生成します。

- **Reusable**: 不要（VM は 1 台）
- **Ephemeral**: 任意（VM を再作成する場合は有効にすると便利）

### 3. 変数ファイルの作成

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を編集して必須値を設定します。

```hcl
project_id         = "your-gcp-project-id"
tailscale_auth_key = "tskey-auth-xxxxx"
```

### 4. デプロイ

```bash
terraform init
terraform plan
terraform apply
```

### 5. Tailscale 側の設定

VM が起動すると Tailscale に自動登録されます。[Admin Console](https://login.tailscale.com/admin/machines) で以下を確認・設定してください。

1. VM がデバイス一覧に表示されていること
2. サブネットルート (`10.10.0.0/24`) を承認
3. 必要に応じて DNS 設定（Split DNS）を構成

## 変数一覧

| 変数名 | 説明 | デフォルト値 |
|--------|------|-------------|
| `project_id` | GCP プロジェクト ID | （必須） |
| `tailscale_auth_key` | Tailscale 認証キー | （必須） |
| `region` | GCP リージョン | `asia-northeast1` |
| `zone` | GCP ゾーン | `asia-northeast1-a` |
| `vm_name` | VM 名 | `dev-vm` |
| `machine_type` | マシンタイプ | `e2-medium` |
| `boot_disk_size` | ブートディスクサイズ (GB) | `50` |
| `network_name` | VPC ネットワーク名 | `dev-network` |
| `subnet_cidr` | サブネット CIDR | `10.10.0.0/24` |

## 接続方法

### Tailscale 経由（通常）

```bash
ssh <tailscale-hostname>
```

### IAP 経由（フォールバック）

```bash
gcloud compute ssh dev-vm --zone=asia-northeast1-a --tunnel-through-iap
```

## トラブルシューティング

### VM 上の Tailscale 状態を確認

```bash
gcloud compute ssh dev-vm --zone=asia-northeast1-a --tunnel-through-iap -- tailscale status
```

### スタートアップスクリプトのログを確認

```bash
gcloud compute ssh dev-vm --zone=asia-northeast1-a --tunnel-through-iap -- cat /var/log/startup-script.log
```

## リソースの削除

```bash
terraform destroy
```

## 参考

- [Tailscale on Google Compute Engine](https://tailscale.com/docs/install/cloud/gce)
- [Tailscale Subnet Routers](https://tailscale.com/kb/1019/subnets)
