import { PrismaClient, Role } from '@prisma/client'; import argon2 from 'argon2';
const prisma = new PrismaClient();
async function main() {
  const email = 'admin@example.com';
  const existing = await prisma.user.findUnique({ where: { email } });
  if (!existing) {
    const hash = await argon2.hash('admin123');
    await prisma.user.create({ data: { email, name: 'Admin', password: hash, role: Role.ADMIN } });
    console.log('Seed: created admin user (admin@example.com / admin123)');
  } else { console.log('Seed: admin already exists'); }
}
main().then(async()=>await prisma.$disconnect()).catch(async(e)=>{console.error(e);await prisma.$disconnect();process.exit(1);});
