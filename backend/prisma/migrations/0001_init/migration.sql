-- enums
CREATE TYPE "Role" AS ENUM ('ADMIN','MANAGER','PM','OPERATOR','VIEWER');
CREATE TYPE "ProjectStatus" AS ENUM ('DRAFT','IN_PROGRESS','IN_REVIEW','APPROVED','CLOSED');
-- tables
CREATE TABLE IF NOT EXISTS "User" (
  "id" TEXT PRIMARY KEY,
  "email" TEXT NOT NULL UNIQUE,
  "name" TEXT,
  "password" TEXT NOT NULL,
  "role" "Role" NOT NULL DEFAULT 'VIEWER',
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS "Project" (
  "id" TEXT PRIMARY KEY,
  "name" TEXT NOT NULL,
  "client" TEXT,
  "status" "ProjectStatus" NOT NULL DEFAULT 'DRAFT',
  "ownerId" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT "Project_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS "Project_name_idx" ON "Project"("name");
CREATE TABLE IF NOT EXISTS "AuditLog" (
  "id" TEXT PRIMARY KEY,
  "actorId" TEXT,
  "action" TEXT NOT NULL,
  "resource" TEXT,
  "meta" JSONB,
  "ip" TEXT,
  "createdAt" TIMESTAMP NOT NULL DEFAULT NOW()
);
