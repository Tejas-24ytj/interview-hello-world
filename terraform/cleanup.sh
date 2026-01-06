#!/bin/bash
# Cleanup script to remove partial infrastructure

echo "🧹 Cleaning up partial infrastructure..."

# Destroy all created resources
terraform destroy -auto-approve

echo "✅ Cleanup complete!"

