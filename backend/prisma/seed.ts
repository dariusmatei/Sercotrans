import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  await prisma.user.upsert({
    where: { email: 'demo@sercotrans.local' },
    create: { email: 'demo@sercotrans.local', name: 'Demo', roles: ['user'] },
    update: {},
  });

  const statuses = ['Draft','InProgress','Approved','Closed'] as const;
  const now = new Date();
  for (let i = 1; i <= 5; i++) {
    await prisma.project.upsert({
      where: { id: `seed-${i}` },
      create: {
        id: `seed-${i}`,
        name: `Demo Project ${i}`,
        client: i % 2 ? 'ACME' : 'Globex',
        status: statuses[i % statuses.length],
        owner: 'Demo',
        dueDate: new Date(now.getTime() + 86400000 * (7 * i)),
      },
      update: {},
    });
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
}).finally(async () => {
  await prisma.$disconnect();
});
