/*
  Warnings:

  - You are about to drop the column `roleId` on the `Employee` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "commerce"."Employee_businessId_roleId_idx";

-- AlterTable
ALTER TABLE "commerce"."Employee" DROP COLUMN "roleId";
