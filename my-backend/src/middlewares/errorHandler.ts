import { Request, Response, NextFunction } from 'express';

export function errorHandler(err: any, req: Request, res: Response, next: NextFunction) {
  const status = err.status || 500;
  const message = err.message || 'Internal Server Error';
  if (process.env.NODE_ENV !== 'production') {
    return res.status(status).json({ status: 'error', message, stack: err.stack });
  }
  return res.status(status).json({ status: 'error', message });
}
