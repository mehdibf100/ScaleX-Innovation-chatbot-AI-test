/*
  Warnings:

  - You are about to alter the column `firebaseUid` on the `Conversation` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(255)`.

*/
-- AlterTable
ALTER TABLE "Conversation" ALTER COLUMN "firebaseUid" SET DATA TYPE VARCHAR(255);

-- CreateTable
CREATE TABLE "Summary" (
    "id" TEXT NOT NULL,
    "conversationId" INTEGER,
    "firebaseUid" VARCHAR(255) NOT NULL,
    "context" TEXT,
    "summary" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Summary_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Summary_conversationId_idx" ON "Summary"("conversationId");

-- CreateIndex
CREATE INDEX "Summary_firebaseUid_idx" ON "Summary"("firebaseUid");

-- CreateIndex
CREATE INDEX "Conversation_firebaseUid_idx" ON "Conversation"("firebaseUid");

-- CreateIndex
CREATE INDEX "Message_conversationId_idx" ON "Message"("conversationId");

-- AddForeignKey
ALTER TABLE "Summary" ADD CONSTRAINT "Summary_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "Conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;
