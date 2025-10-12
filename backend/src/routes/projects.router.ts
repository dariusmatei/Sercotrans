import type { Request, Response, Router } from 'express';
import express from 'express';
import { prisma } from '../db/prisma';

const router: Router = express.Router();

// GET /api/projects
router.get('/api/projects', async (req: Request, res: Response) => {
  const { search = '', status = '', sort = 'name', dir = 'asc', page = '1', pageSize = '50' } = req.query as Record<string, string>;

  const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
  const sizeNum = Math.min(200, Math.max(1, parseInt(String(pageSize), 10) || 50));

  const where: any = {};
  if (status) where.status = { equals: String(status) };

  if (search) {
    const s = String(search);
    where.OR = [
      { name: { contains: s, mode: 'insensitive' } },
      { client: { contains: s, mode: 'insensitive' } },
      { owner: { contains: s, mode: 'insensitive' } },
    ];
  }

  const orderByMap: Record<string, any> = {
    name: { name: dir === 'desc' ? 'desc' : 'asc' },
    client: { client: dir === 'desc' ? 'desc' : 'asc' },
    status: { status: dir === 'desc' ? 'desc' : 'asc' },
    owner: { owner: dir === 'desc' ? 'desc' : 'asc' },
    dueDate: { dueDate: dir === 'desc' ? 'desc' : 'asc' },
    createdAt: { createdAt: dir === 'desc' ? 'desc' : 'asc' },
  };
  const orderBy = orderByMap[sort] ?? orderByMap['name'];

  const skip = (pageNum - 1) * sizeNum;
  const take = sizeNum;

  const [items, total] = await Promise.all([
    prisma.project.findMany({ where, orderBy, skip, take }),
    prisma.project.count({ where }),
  ]);

  res.json({ items, total, page: pageNum, pageSize: sizeNum });
});

// GET /api/projects/:id
router.get('/api/projects/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const p = await prisma.project.findUnique({ where: { id } });
  if (!p) return res.status(404).json({ message: 'Project not found' });
  res.json(p);
});

// POST /api/projects
router.post('/api/projects', async (req: Request, res: Response) => {
  const { name, client, status = 'Draft', owner, dueDate } = req.body || {};
  if (!name) return res.status(400).json({ message: 'name is required' });
  if (!owner) return res.status(400).json({ message: 'owner is required' });

  const created = await prisma.project.create({
    data: {
      name: String(name),
      client: String(client || ''),
      status: String(status || 'Draft'),
      owner: String(owner),
      dueDate: dueDate ? new Date(dueDate) : null,
    },
  });
  res.status(201).json(created);
});

// PATCH /api/projects/:id
router.patch('/api/projects/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { name, client, status, owner, dueDate } = req.body || {};

  try {
    const updated = await prisma.project.update({
      where: { id },
      data: {
        ...(name !== undefined ? { name: String(name) } : {}),
        ...(client !== undefined ? { client: String(client) } : {}),
        ...(status !== undefined ? { status: String(status) } : {}),
        ...(owner !== undefined ? { owner: String(owner) } : {}),
        ...(dueDate !== undefined ? { dueDate: dueDate ? new Date(dueDate) : null } : {}),
      },
    });
    res.json(updated);
  } catch (e) {
    res.status(404).json({ message: 'Project not found' });
  }
});

export default router;
