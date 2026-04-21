module.exports = {
  apps: [
    {
      name: "phase2-settlement-worker",
      cwd: "c:/Users/hp/gmaing/workers/phase2-settlement-worker",
      script: "npm.cmd",
      args: "run dev",
      interpreter: "none",
      watch: false,
      autorestart: true,
      max_restarts: 20,
      restart_delay: 5000,
      env: {
        NODE_ENV: "production"
      },
      out_file: "c:/Users/hp/gmaing/workers/phase2-settlement-worker/logs/out.log",
      error_file: "c:/Users/hp/gmaing/workers/phase2-settlement-worker/logs/error.log",
      time: true
    }
  ]
};
